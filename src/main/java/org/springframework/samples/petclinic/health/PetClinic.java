package org.springframework.samples.petclinic.health;


import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;
import java.util.HashMap;
import java.util.Map;

@Component
public class PetClinic implements HealthIndicator {

    @Value("#{systemEnvironment['HOSTNAME']}")
    private String hostname;

    private boolean healthy = true;

    @Override
    public Health health() {
        if (this.healthy) {
            return this.up();
        }

        return this.down();
    }

    public Map<String, Object> getDetail() {
        Map<String, Object> details = new HashMap<>();

        details.put("container", this.hostname);

        return details;
    }

    public boolean isUp() {
        return this.healthy;
    }

    public Health up() {
        this.healthy = true;

        return Health.up().withDetails(this.getDetail()).build();
    }

    public Health down() {
        this.healthy = false;

        return Health.down().withDetails(this.getDetail()).build();
    }
}
