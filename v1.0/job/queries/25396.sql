
WITH Movies_With_Cast AS (
    SELECT 
        a.title,
        a.production_year,
        c.person_id,
        ak.name AS actor_name,
        ak.surname_pcode,
        ak.md5sum AS actor_md5sum
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
        AND ak.name IS NOT NULL
),
Actor_Performance AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count,
        STRING_AGG(title, ', ') AS movies,
        MIN(production_year) AS first_movie_year,
        MAX(production_year) AS last_movie_year
    FROM 
        Movies_With_Cast
    GROUP BY 
        actor_name
),
Actor_Info AS (
    SELECT 
        ap.actor_name,
        ap.movie_count,
        ap.first_movie_year,
        ap.last_movie_year,
        pi.info AS additional_info
    FROM 
        Actor_Performance ap
    LEFT JOIN 
        person_info pi ON ap.actor_name = (SELECT name FROM aka_name WHERE person_id = pi.person_id LIMIT 1)
    WHERE 
        ap.movie_count > 5
)
SELECT 
    ai.actor_name,
    ai.movie_count,
    ai.first_movie_year,
    ai.last_movie_year,
    ai.additional_info,
    REPLACE(REPLACE(REPLACE(REPLACE(ap.movies, ';', ','), ' ', '_'), ',', ', '), '', '') AS formatted_movies
FROM 
    Actor_Info ai
JOIN 
    Actor_Performance ap ON ai.actor_name = ap.actor_name
ORDER BY 
    ai.movie_count DESC, ai.last_movie_year DESC;
