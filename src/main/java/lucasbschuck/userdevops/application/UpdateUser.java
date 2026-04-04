package lucasbschuck.userdevops.application;

import lombok.AllArgsConstructor;
import lucasbschuck.userdevops.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
@AllArgsConstructor
public class UpdateUser {
    private UserRepository userRepository;

    public boolean execute(String email, String name) {
        return userRepository.findUsersByEmail(email)
                .map(user -> {
                    user.setName(name);
                    userRepository.save(user);
                    return true;
                })
                .orElse(false);
    }
}
