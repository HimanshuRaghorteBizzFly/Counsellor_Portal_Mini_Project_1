package in.ashokit.config;

import java.util.Arrays;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import in.ashokit.entities.Course;
import in.ashokit.repo.CourseRepo;

/**
 * Initializes essential seed data (e.g. course options) if starting on an empty database.
 */
@Component
public class DataInitializer implements CommandLineRunner {

	@Autowired
	private CourseRepo courseRepo;

	@Override
	public void run(String... args) {
		try {
			if (courseRepo.count() == 0) {
				List<String> defaultCourses = Arrays.asList(
					"Java Full Stack",
					"Python Full Stack",
					"DevOps & Cloud (AWS)",
					"Data Science & AI",
					"Full Stack Web Development"
				);

				for (String name : defaultCourses) {
					Course course = new Course();
					course.setCourseName(name);
					courseRepo.save(course);
				}
			}
		} catch (Exception e) {
			System.err.println("Notice: Course data initialization skipped: " + e.getMessage());
		}
	}
}
