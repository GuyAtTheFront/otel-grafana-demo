package com.example.GrafanaDemo.controller;

import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MyController {

    private static final org.slf4j.Logger logger = LoggerFactory.getLogger(MyController.class);
    
    @GetMapping("/test")
    public String test() {
        logger.info("logging test");
        logger.info("new log");
        return "hello";
    }

}
