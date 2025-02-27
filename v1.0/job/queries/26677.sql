WITH MovieDetails AS (
    SELECT
        t.title,
        t.production_year,
        a.name AS actor_name,
        p.gender,
        kc.keyword AS keyword
    FROM title t
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN name p ON a.person_id = p.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword kc ON mk.keyword_id = kc.id
    WHERE
        t.production_year >= 2000
        AND p.gender = 'F'
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
        AND mi.info IS NOT NULL
),
TopMovies AS (
    SELECT
        title,
        production_year,
        COUNT(*) AS actor_count,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM MovieDetails
    GROUP BY title, production_year
)
SELECT
    title,
    production_year,
    actor_count,
    actors,
    keywords
FROM TopMovies
WHERE 
    actor_count > 5
ORDER BY production_year DESC, actor_count DESC
LIMIT 10;
