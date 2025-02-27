WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.id AS movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
),
TopActors AS (
    SELECT 
        movie_id,
        STRING_AGG(actor_name, ', ') AS actor_names
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
    GROUP BY 
        movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ta.actor_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    RankedMovies rt
JOIN 
    TopActors ta ON rt.movie_id = ta.movie_id
LEFT JOIN 
    movie_keyword mk ON rt.movie_id = mk.movie_id
GROUP BY 
    rt.title, rt.production_year, ta.actor_names
ORDER BY 
    rt.production_year DESC, rt.title;

This SQL query selects movies produced between 2000 and 2023 along with details about the top three actors in each movie, and counts the number of distinct keywords associated with those movies. The query uses Common Table Expressions (CTEs) for improved readability and manages aggregates using GROUP BY and COUNT functions.
