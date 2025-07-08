
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT cc.movie_id) AS total_movies,
        LISTAGG(DISTINCT tm.title, ', ') WITHIN GROUP (ORDER BY tm.title) AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info cc ON a.person_id = cc.person_id
    JOIN 
        TopRankedMovies tm ON cc.movie_id = tm.movie_id
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    ai.name,
    ai.total_movies,
    ai.movies,
    CASE 
        WHEN ai.total_movies > 3 THEN 'Prolific Actor'
        WHEN ai.total_movies IS NULL THEN 'Newcomer'
        ELSE 'Average Actor'
    END AS actor_category,
    COALESCE(NULLIF(SUBSTR(ai.movies, 1, 50), ''), 'No movies listed') AS short_movie_list
FROM 
    ActorInfo ai
WHERE 
    ai.total_movies > 0
ORDER BY 
    ai.total_movies DESC;
