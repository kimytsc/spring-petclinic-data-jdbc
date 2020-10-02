package org.springframework.samples.petclinic.health;


import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.health.Health;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Controller;

@RestController
public class HealthController {

    @Autowired
    private PetClinic petclinic;

    @GetMapping("/up")
    public Health up() {
        return petclinic.up();
    }

    @GetMapping("/down")
    @ResponseStatus(HttpStatus.SERVICE_UNAVAILABLE)
    public Health down() {
        return petclinic.down();
    }
}
