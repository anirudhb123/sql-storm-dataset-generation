WITH RECURSIVE ActorFilmography AS (
    SELECT 
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        1 AS level
    FROM 
        aka_name ka 
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        aka_title kt ON c.movie_id = kt.id
    WHERE 
        ka.name IS NOT NULL

    UNION ALL

    SELECT 
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        af.level + 1
    FROM 
        ActorFilmography af
    JOIN 
        cast_info c ON af.actor_name = ka.name
    JOIN 
        aka_title kt ON c.movie_id = kt.id
    WHERE 
        kt.production_year IS NOT NULL
        AND af.level < 5  -- Limit the recursion to 5 levels deep
),

KeywordCount AS (
    SELECT 
        ka.person_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    GROUP BY 
        ka.person_id
),

RankedActors AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY production_year DESC) AS rank
    FROM 
        ActorFilmography
)

SELECT 
    a.actor_name,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    ra.movie_title,
    ra.production_year,
    ra.rank
FROM 
    RankedActors ra 
LEFT JOIN 
    KeywordCount kc ON ra.actor_name = (SELECT name FROM aka_name WHERE person_id IN (SELECT person_id FROM cast_info WHERE movie_id = ra.movie_title) LIMIT 1)
WHERE 
    ra.rank <= 2
ORDER BY 
    a.actor_name, 
    ra.production_year DESC;
This elaborate SQL query accomplishes several tasks:
- It uses a recursive CTE (`ActorFilmography`) to fetch the filmography of actors up to 5 levels deep, which also includes productions with NULL years.
- The `KeywordCount` CTE counts associated keywords for each actor.
- The `RankedActors` CTE assigns a rank based on the most recent production per actor.
- Finally, the main query joins these results, obtaining the actor names, keyword counts, movie titles, production years, and ranks. It uses a LEFT JOIN to incorporate relevant keyword counts into the actor's filmography and applies sorting to finalize the output.
