package in.ashokit.controller;

import java.sql.Connection;
import java.util.HashMap;
import java.util.Map;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Health check endpoint for Docker containers, Kubernetes probes,
 * load balancers, and deployment platforms.
 */
@RestController
public class HealthController {

	@Autowired(required = false)
	private DataSource dataSource;

	@GetMapping({"/health", "/api/health"})
	public ResponseEntity<Map<String, Object>> healthCheck() {
		Map<String, Object> health = new HashMap<>();
		health.put("status", "UP");
		health.put("service", "counsellor-portal");
		health.put("timestamp", System.currentTimeMillis());

		boolean dbConnected = false;
		if (dataSource != null) {
			try (Connection conn = dataSource.getConnection()) {
				dbConnected = conn.isValid(2);
			} catch (Exception e) {
				dbConnected = false;
			}
		}
		health.put("database", dbConnected ? "UP" : "DOWN");

		return ResponseEntity.ok(health);
	}
}
