package lucasbschuck.userdevops.application;

import lombok.AllArgsConstructor;
import lucasbschuck.userdevops.model.User;
import lucasbschuck.userdevops.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@AllArgsConstructor
@Service
public class FindUserByEmail {
    private UserRepository userRepository;

    public Optional<User> execute(String email) {
        return userRepository.findUsersByEmail(email);
    }
}
