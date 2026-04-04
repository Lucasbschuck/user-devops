package lucasbschuck.userdevops.application;

import lombok.AllArgsConstructor;
import lucasbschuck.userdevops.model.User;
import lucasbschuck.userdevops.repository.UserRepository;
import org.springframework.stereotype.Service;

@AllArgsConstructor
@Service
public class CreateUser {
    private UserRepository userRepository;

    public void execute(String name, String email) {
        userRepository.findUsersByEmail(email).ifPresent(user -> {
            throw new RuntimeException("User with this email already registered!");
        });
        userRepository.save(new User(name, email));
    }
}
