WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.production_year > 2000
),
MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(ci.person_id) AS total_actors
    FROM complete_cast c
    JOIN cast_info ci ON c.subject_id = ci.person_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY c.movie_id, a.name, r.role
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keyword,
    mc.actor_name,
    mc.role_name,
    mc.total_actors
FROM RankedMovies rm
JOIN MovieCast mc ON rm.movie_id = mc.movie_id
WHERE rm.rn = 1
ORDER BY rm.production_year DESC, mc.total_actors DESC;
