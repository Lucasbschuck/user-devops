package lucasbschuck.userdevops.application;

import lombok.AllArgsConstructor;
import lucasbschuck.userdevops.repository.UserRepository;
import org.springframework.stereotype.Service;

@AllArgsConstructor
@Service
public class DeleteUser {
    private UserRepository userRepository;

    public void execute(String email) {
        userRepository.findUsersByEmail(email).ifPresent(userRepository::delete);
    }
}
