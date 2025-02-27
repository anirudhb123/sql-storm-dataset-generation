WITH RecursiveActors AS (
    SELECT 
        c.person_id,
        COUNT(c.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY COUNT(c.movie_id) DESC) AS rn
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
MoviesWithGenre AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS genre,
        COALESCE(mi.info, 'No Info') AS additional_info
    FROM 
        aka_title t
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
),
ActorsInMovies AS (
    SELECT 
        ra.person_id,
        wm.movie_id,
        wm.title,
        wm.production_year,
        wm.genre,
        wm.additional_info,
        RANK() OVER (PARTITION BY wm.movie_id ORDER BY ra.movie_count DESC) AS actor_rank
    FROM 
        RecursiveActors ra
    JOIN 
        cast_info ci ON ra.person_id = ci.person_id
    JOIN 
        MoviesWithGenre wm ON ci.movie_id = wm.movie_id
)
SELECT 
    am.person_id,
    COUNT(DISTINCT am.movie_id) AS total_movies,
    MAX(am.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT am.title, ', ') AS movie_titles,
    CASE
        WHEN COUNT(DISTINCT am.movie_id) > 10 THEN 'Prolific'
        WHEN COUNT(DISTINCT am.movie_id) BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Novice'
    END AS actor_level,
    AVG(CASE WHEN am.actor_rank = 1 THEN 1 ELSE 0 END) * 100 AS star_percentage
FROM 
    ActorsInMovies am
GROUP BY 
    am.person_id
HAVING 
    COUNT(DISTINCT am.movie_id) > 2
ORDER BY 
    total_movies DESC NULLS LAST;
