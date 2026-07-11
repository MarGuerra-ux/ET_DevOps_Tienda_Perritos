package karate;

import com.intuit.karate.junit5.Karate;

public class KarateTest {

    @Karate.Test
    Karate todos() {
        return Karate.run(
            "health",
            "productos",
            "productos_get",
            "productos_404",
            "productos_json",
            "productos_post",
            "productos_tiempo"
        ).relativeTo(getClass());
    }

}