package lucasbschuck.userdevops.controllers;

import lombok.AllArgsConstructor;
import lucasbschuck.userdevops.application.CreateUser;
import lucasbschuck.userdevops.application.DeleteUser;
import lucasbschuck.userdevops.application.FindUserByEmail;
import lucasbschuck.userdevops.application.UpdateUser;
import lucasbschuck.userdevops.model.User;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RequestMapping("/user")
@RestController
@AllArgsConstructor
public class UserDevopsController {
    private CreateUser createUser;
    private DeleteUser deleteUser;
    private FindUserByEmail findUserByEmail;
    private UpdateUser updateUser;


    @GetMapping
    public ResponseEntity<User> getUser(@RequestParam String email) {
        return findUserByEmail.execute(email)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<String> createUser(@RequestBody User user) {
        createUser.execute(user.getName(), user.getEmail());
        return ResponseEntity.ok("User created successfully");
    }

    @PutMapping
    public ResponseEntity<String> updateUser(@RequestBody User user) {
        boolean updated = updateUser.execute(user.getEmail(), user.getName());

        if (updated) {
            return ResponseEntity.ok("User updated successfully");
        }
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("User not found");
    }

    @DeleteMapping
    public ResponseEntity<String> deleteUser(@RequestParam String email) {
        deleteUser.execute(email);
        return ResponseEntity.ok("User deleted successfully");
    }

}
