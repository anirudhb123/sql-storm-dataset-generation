WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year > 2000
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
ActorStats AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_notes
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        TopMovies tm ON ci.movie_id IN (SELECT DISTINCT id FROM aka_title WHERE title = tm.title)
    GROUP BY 
        a.id, a.name
),
MovieGenres AS (
    SELECT 
        mt.id AS movie_id,
        GROUP_CONCAT(DISTINCT kt.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.id
)
SELECT 
    as.actor_id,
    as.actor_name,
    as.total_movies,
    as.movies_with_notes,
    COUNT(DISTINCT mg.movie_id) AS genre_count,
    MAX(mg.genres) AS all_genres
FROM 
    ActorStats as
LEFT JOIN 
    MovieGenres mg ON as.total_movies = (SELECT COUNT(DISTINCT movie_id) FROM cast_info WHERE person_id = as.actor_id)
WHERE 
    as.total_movies > 0
GROUP BY 
    as.actor_id, as.actor_name
HAVING 
    COUNT(DISTINCT mg.movie_id) > 0
ORDER BY 
    as.total_movies DESC, as.actor_name;
