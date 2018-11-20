#!/usr/bin/ruby
# Written by Sourav Goswami <souravgoswami@protonmail.com>. Thanks to Ruby2D community!
# GNU General Public License v3.0

require 'ruby2d'

module Ruby2D
	def change_colour=(colour)
		opacity_, self.color = self.opacity, colour
		self.opacity = opacity_
	end
end

def main()
	$width, $height, $fps = 640, 480, 30
	set title: 'Lost in Migration', width: $width, height: $height, fps_cap: $fps, resizable: true

	reduce = ->(objects, val=0.1, threshold=0.5) {
		objects.each do |object| object.opacity -= val if object.opacity > threshold end
	}

	increase = ->(objects, val=0.1, threshold=1) {
		objects.each do |object|	object.opacity += val if object.opacity < threshold end
	}

	# Nature stuffs
	bg_colours = %w(#3c4f8b #3c4f8b #eae889 #d1739c)
	bg = Rectangle.new width: $width, height: $height, color: bg_colours, z: -1000

	sun = []
	20.times do |temp|
		sun_ = Circle.new radius: (temp + 1), x: $width/1.15, z: -temp - 100, y: 350
		sun_.color = temp < 15 ? '#ffffff' : '#ffff00'
		sun_.opacity = temp/45.0
		sun << sun_
	end

	stars = []
	($width/3).times { stars.push(Square.new(size: rand(1.0..3.0), x: rand(0..$width), y: rand(0..$height), z: -100)) }

	snow, snow_speed = [], []
	($width/15).times do |temp|
		snow << Circle.new(radius: rand(1..3), x: rand(0..$width), y: rand(0..$height), z: -110)
		snow_speed << rand(1.0..3.0)
	end

	flares = []
	10.times do |temp|
		flare = Circle.new radius: temp * 5, x: $width/1.15, y: 350, z: -102, color: 'white'
		flare.opacity = 0.1
		flares << flare
	end

	bg_image = Image.new 'images/silhoutte.png', z: -100, color: '#000000'
	bg_image.opacity = 1
	bg_image.y = $height - bg_image.height

	question = Text.new "What's the middle bird's position?", font: 'fonts/Alice/Alice-Regular.ttf'
	question.x, question.y = $width/2 - question.width/2, $height - question.height

	# Game
	birds = Image.new "birds/#{(1..4).to_a.sample}.png", rotate: [0, 90, 180, 270].sample
	birds.x, birds.y = rand(0..$width - birds.width), rand(20..bg_image.y - birds.height)
	m_bird = Image.new 'birds/bird.png', rotate: [0, 90, 180, 270].sample
	m_bird.x, m_bird.y = birds.x + birds.width/2 - m_bird.width/2, birds.y + birds.height/2 - m_bird.height/2

	up, down, right , left, pressed = false, false, false, false, false

	total_time = 60

	started = false

	circle1 = Image.new 'images/circle.png', width: 20, height: 20
	circle1.opacity = 0

	circle2 = Image.new 'images/circle.png', width: 20, height: 20
	circle2.opacity = 0

	connect_line = Line.new color: '#3ce3b4'
	circle1.opacity = circle2.opacity = connect_line.opacity = 0

	pause_var, score, streak = 1, 0, 0

	pause_box_touched = false
	pause_box = Rectangle.new z: 10, x: 1, y: 1
	pause_box_image = Image.new 'images/pause.png', x: pause_box.x, y: pause_box.y, z: 10
	pause_box.width, pause_box.height = pause_box_image.x + pause_box_image.width, pause_box_image.y + pause_box_image.height
	pause_label = Text.new "Play/Pause", x: pause_box_image.x + pause_box_image.width, font: 'fonts/Alice/Alice-Regular.ttf', z: pause_box.z + 1, color: 'teal'

	score_box_touched = false
	score_box = Rectangle.new y: 1

	time_box_touched = false
	time_box = Rectangle.new y: 1

	score_label = Text.new "Score: #{score}", font: 'fonts/Alice/Alice-Regular.ttf', color: 'teal'
	time_label = Text.new "Time: ", font: 'fonts/Alice/Alice-Regular.ttf', color: 'teal'

	circle = Circle.new color: '#000000', z: 15
	circle.opacity = 0.5
	mouse_pressed = false

	pause_screen = Rectangle.new width: $width, height: $height, color: 'black', z: pause_box.z - 1
	pause_screen.opacity = 0

	play_button_touched = false
	play_button = Image.new 'images/play_button.png', z: pause_box.z
	play_button.x, play_button.y = $width/2 - play_button.width/2, $height/2 - play_button.height/2

	play_touched = false
	play = Image.new 'images/play_button_64x64.png', z: play_button.z
	play.x, play.y = pause_box_image.x + pause_box_image.width, pause_box_image.y + pause_box_image.height

	restart_touched = false
	restart = Image.new 'images/restart.png', z: play_button.z
	restart.x, restart.y = $width - pause_box_image.x - pause_box_image.width - restart.width, pause_box_image.y + pause_box_image.height

	power_touched = false
	power = Image.new 'images/power.png', z: play_button.z
	power.x, power.y = play.x, $height - play.y - power.height

	about_touched = false
	about = Image.new 'images/bulb.png', z: play_button.z
	about.x, about.y = restart.x, power.y

	final_score_touched = false
	final_score = Text.new '', font: 'fonts/Alice/Alice-Regular.ttf', size: 50, z: pause_box.z
	final_score.opacity = 0

	i = 0
	air = [-1, 0, 1].sample
	nature_variable = 0
	countdown = 0
	pause_var = 0

	counter_label_touched = false
	counter_label = Text.new '', font: 'fonts/Alice/Alice-Regular.ttf', size: 35, z: play_button.z

	beep = Sound.new 'sounds/beep.wav'
	correct = Sound.new 'sounds/131662__bertrof__game-sound-correct-v2.wav'
	wrong = Sound.new 'sounds/131657__bertrof__game-sound-wrong.wav'
	start_game = Sound.new 'sounds/start_game.ogg'

	correct_img = Image.new 'images/correct.png'
	wrong_img = Image.new 'images/wrong.png'
	correct_img.opacity, wrong_img.opacity = 0, 0

	message = Image.new 'images/message.png', z: 15
	message.opacity = 0

	message_label = Text.new "Hi", font: 'fonts/Alice/Alice-Regular.ttf', size: 12, color: 'orange', z: 15
	message_label.opacity = 0

	message_control = ->(obj, text='Ruby', colour='green') {
		increase.call([message, message_label], 0.1)
		message.x, message.y = obj.x + obj.width/2 - message.width/2, obj.y + obj.height

		message_label.text, message_label.change_colour = text, colour
		message_label.x, message_label.y = message.x + message.width/2 - message_label.width/2, message.y + message.height/1.5 - message_label.height/2
	}

	change_scores = ->(valid=true) {
		if valid
			Thread.new { correct.play }
			score += 1 + streak
			streak += 1
			correct_img.width, correct_img.height, correct_img.opacity = 50, 50, 1
		else
			Thread.new { wrong.play }
			streak = 0
			wrong_img.width, wrong_img.height, wrong_img.opacity = 50, 50, 1
		end
	}

	manage_score = -> {
		if started
			case m_bird.rotate
			when 0
				if up then change_scores.call(true)
					else change_scores.call(false) end
			when 180
				if down then change_scores.call(true)
					else change_scores.call(false) end
			when 90
				 if right then change_scores.call(true)
					else change_scores.call(false) end
			when 270
				if left then change_scores.call(true)
					else change_scores.call(false) end
			end
			up, down, left, right = false, false, false, false
			birds.remove
			m_bird.remove
			birds = Image.new "birds/#{(1..4).to_a.sample}.png", rotate: [0, 90, 180, 270].sample
			birds.x, birds.y = rand(0..$width - birds.width), rand(time_box.height + 20..bg_image.y - birds.height)
			m_bird = Image.new 'birds/bird.png', rotate: [0, 90, 180, 270].sample
			m_bird.x, m_bird.y = birds.x + birds.width/2 - m_bird.width/2, birds.y + birds.height/2 - m_bird.height/2
		end
	}

	on :key_down do |k|
		if %w(up w down s right d left a).include?(k.key)
			pressed = true
			up = %w(up w).include?(k.key) ? true : false
			down = %w(down s).include?(k.key) ? true : false
			right = %w(right d).include?(k.key) ? true : false
			left = %w(left a).include?(k.key) ? true : false
		end
		pause_var += 1 if %w(escape space p).include?(k.key)
	end

	on :key_up do |k|
		if %w(up w down s right d left a).include?(k.key)
			manage_score.call
			pressed = false
		end
	end

	current_x = 0
	selected_coordinate_x = 0

	current_y = 0
	selected_coordinate_y = 0

	on :mouse_move do |e|
		pause_box_touched = pause_box.contains?(e.x, e.y) ? true : false
		if pressed
			current_x -= e.delta_x
			current_y -= e.delta_y

			up = selected_coordinate_y < current_y ? true : false
			down = selected_coordinate_y > current_y ? true : false
			right = selected_coordinate_x > current_x ? true : false
			left = selected_coordinate_x < current_x ? true : false

			circle1.x, circle1.y = e.x - circle1.width/2, e.y - circle1.height/2
		end

		score_box_touched = score_box.contains?(e.x, e.y) ? true : false
		time_box_touched = time_box.contains?(e.x, e.y) ? true : false

		play_button_touched = play_button.contains?(e.x, e.y) ? true : false
		play_touched = play.contains?(e.x, e.y) ? true : false
		restart_touched = restart.contains?(e.x, e.y) ? true : false
		power_touched = power.contains?(e.x, e.y) ? true : false
		about_touched = about.contains?(e.x, e.y) ? true : false
		counter_label_touched = counter_label.contains?(e.x, e.y) ? true : false
		final_score_touched = final_score.contains?(e.x, e.y) ? true : false
	end

	on :mouse_down do |e|
		if time_box.contains?(e.x, e.y)
		elsif score_box.contains?(e.x, e.y)
		elsif pause_box.contains?(e.x, e.y)
		else
			if [:left, :middle].include?(e.button)
				current_x, current_y = e.x, e.y
				selected_coordinate_x, selected_coordinate_y = e.x, e.y

				pressed = true

				circle1.x, circle1.y = e.x - circle1.width/2, e.y - circle1.height/2
				circle2.x, circle2.y = e.x - circle2.width/2, e.y - circle2.height/2
				circle1.opacity = circle2.opacity = connect_line.opacity = 1
			else
				mouse_pressed = true
			end
		end
	end

	on :mouse_up do |e|
		mouse_pressed = false
		pressed = false unless [:left, :middle].include?(e.button)
		if pressed
			manage_score.call
			pressed = false
		end
		pause_var += 1 if pause_box.contains?(e.x, e.y)
		if !started
			pause_var += 1 if play.contains?(e.x, e.y) || play_button.contains?(e.x, e.y) || counter_label.contains?(e.x, e.y)
			if restart.contains?(e.x, e.y)
				score, i, pause_var = 0, 0, 1
				time_label.text, score_label.text = 'Time: ', 'Score: 0'
			end
			exit 0 if power.contains?(e.x, e.y)
			Thread.new { system('ruby', 'stats.rb') } if about.contains?(e.x, e.y)
		end
	end

	update do
		# UI stuffs
		if pause_var % 2 == 1
				# Thread.new { beep.play } if countdown % $fps == 0 and !started
			case countdown/$fps
				when 0 then counter_label.text = 'Ready' ; beep.play if countdown % $fps == 0
				when 1 then counter_label.text = 'Steady' ; beep.play if countdown % $fps == 0
				when 2 then counter_label.text = 'Go!' ; beep.play if countdown % $fps == 0
				else
					Thread.new { start_game.play } if !started
					started = true
			end
				counter_label.x, counter_label.y = play_button.x + play_button.width/2 - counter_label.width/2, play_button.y + play_button.height
				countdown += 1 if !started
				reduce.call([counter_label], 0.05, 0)
		else
			started, countdown, counter_label.text = false, 0, 'Play'
			counter_label.x, counter_label.y = play_button.x + play_button.width/2 - counter_label.width/2, play_button.y + play_button.height
		end

		if mouse_pressed
			increase.call([circle], 0.1, 0.5)
			circle.radius = circle.radius < 10 ? circle.radius + 1 : 1
			circle.x, circle.y = get(:mouse_x), get(:mouse_y)
		else
			reduce.call([circle], 0.2, 0)
		end

		if pause_box_touched
			increase.call([pause_label]) if pause_box.width > pause_label.x + pause_label.width/4
			increase.call([pause_box])
			pause_box.width += 10 if pause_box.width < pause_label.x + pause_label.width + 5
		else
			reduce.call([pause_label], 0.15, 0)
			reduce.call([pause_box])
			pause_box.width -= 8 if pause_box.width >= pause_box_image.x + pause_box_image.width + 5
		end

		# Game
		if started
			i += 1
			reduce.call([pause_screen, play_button, play, restart, power, about, counter_label, final_score], 0.1, 0)
			if time_box_touched
				message_control.call(time_box, 'Time', '#008080')
			elsif score_box_touched
				message_control.call(score_box, 'Score', '#800080')
			elsif pause_box_touched
				message_control.call(pause_box, 'Pause', '#00ff00')
			elsif m_bird.contains?(get(:mouse_x), get(:mouse_y))
				message_control.call(m_bird, 'Birds', '#ff50a6')
			else
				reduce.call([message, message_label], 0.1, 0)
			end

			elapsed_time = total_time.-(i/$fps)

			if elapsed_time <= 0
				pause_var += 1

				final_score.opacity = 1
				final_score.text = "Score: #{score}"
				final_score.x, final_score.y = $width/2 - final_score.width/2, play_button.y - final_score.height

				File.open('data/data', 'a') { |file| file.puts score }

				score, i = 0, 0
			end

			time_label.text = "Time: #{elapsed_time}"
			score_label.text = "Score:\t\t#{score}"

			score_box_touched ? reduce.call([score_box]) : increase.call([score_box])
			time_box_touched ? reduce.call([time_box]) : increase.call([time_box])

			if pressed
				circle1.rotate += 10
				connect_line.x1 = circle2.x + circle2.width/2 - connect_line.width/2
				connect_line.x2 = circle1.x + circle1.width/2 - connect_line.width/2
				connect_line.y1 = circle2.y + circle2.height/2 - connect_line.width/2
				connect_line.y2 = circle1.y + circle1.height/2 - connect_line.width/2
			else
				reduce.call([connect_line, circle1, circle2], 0.2, 0)
				increase.call([birds, m_bird])
			end
		else
			circle1.opacity = circle2.opacity = connect_line.opacity = 0
			increase.call([pause_screen], 0.1, 0.5)
			increase.call([play, restart, power, about, counter_label], 0.1)

			if play_button_touched then play_button.b -= 0.1 if play_button.b > 0.3
				else play_button.b += 0.1 if play_button.b < 1 end

			if play_touched then play.g -= 0.1 if play.g > 0.5
				else play.g += 0.1 if play.g < 1 end

			if restart_touched then restart.g -= 0.1 if restart.g > 0.5
				else restart.g += 0.1 if restart.g < 1 end

			if power_touched then power.g -= 0.1 if power.g > 0.5
				else power.g += 0.1 if power.g < 1 end

			if about_touched then about.g -= 0.1 if about.g > 0.5
				else about.g += 0.1 if about.g < 1 end

			if play_touched then message_control.call(play, 'Play', '#00ff00')
				elsif pause_box_touched then message_control.call(pause_box, 'Play', '#00ff00')
				elsif restart_touched then message_control.call(restart, 'Restart', '#ff55aa')
				elsif power_touched then message_control.call(power, 'Exit', '#ff0000')
				elsif about_touched then message_control.call(about, 'Stats', '#0000ff')
				elsif counter_label_touched then message_control.call(counter_label, 'Play', '#ba3c6b')
				elsif (final_score_touched && final_score.opacity > 0) then message_control.call(final_score, "#{final_score.text.scan(/[0-9]/).*('')}", '#3ce3b4')
				else reduce.call([message, message_label], 0.2, 0)
			end

			counter_label_touched ? reduce.call([play_button], 0.05, 0.6) : increase.call([play_button])
		end

		reduce.call([correct_img, wrong_img], 0.05, 0)

		if correct_img.opacity > 0
			correct_img.width -= 5 if correct_img.width > 0
			correct_img.height -= 5 if correct_img.height > 0
			correct_img.x, correct_img.y = $width/2 - correct_img.width/2, question.y - correct_img.height
		end

		if wrong_img.opacity > 0
			wrong_img.width -= 5 if wrong_img.width > 0
			wrong_img.height -= 5 if wrong_img.height > 0
			wrong_img.x, wrong_img.y = $width/2 - wrong_img.width/2, question.y - wrong_img.height
		end

		time_box.x = score_box.x - time_box.width- 2
		time_box.width, time_box.height = 85, time_label.height
		time_label.x = time_box.x + time_box.width/2 - time_label.width/2

		score_box.x = $width - score_box.width - 1
		score_box.width, score_box.height = score_label.width + 10, score_label.height
		score_label.x = score_box.x + score_box.width/2 - score_label.width/2

		# Nature animation stuffs
		nature_variable += 1
		air = [-1,0,1].sample if nature_variable/$fps.to_f % 5 == 0
		snow.each_with_index do |val, temp|
			val.y += snow_speed[temp] + air.abs
			val.x += air
			if val.y >= $height + val.radius || (val.x >= $width + val.radius || val.x <= -val.radius)
				val.x, val.y = rand(0..$width), 0
				val.radius = rand(1..3)
				snow_speed.delete_at(temp)
				snow_speed.insert(temp, rand(1.0..3.0))
				val.opacity = 1
			end
		end

		for val in sun do val.radius += Math.cos(nature_variable/3)/10 end
		for val in flares
			val.radius += 1.3
			val.opacity -= 0.002
			val.radius, val.opacity = 1, 0.1 if val.radius >= 60
		end

		stars.sample(5).each do |val| val.opacity = [0, 1, 1].sample end
	end
	show
end
main
