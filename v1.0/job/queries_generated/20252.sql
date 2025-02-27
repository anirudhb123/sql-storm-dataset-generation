WITH RecursiveCTE AS (
    SELECT
        c.id AS cast_id,
        p.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS actor_rk
    FROM
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        production_year,
        COUNT(*) AS total_actors,
        COUNT(DISTINCT movie_title) AS total_movies,
        AVG(actor_rk) AS avg_actor_rank
    FROM 
        RecursiveCTE
    GROUP BY 
        production_year
),
RankedMovies AS (
    SELECT
        ms.production_year,
        ms.total_actors,
        ms.total_movies,
        ms.avg_actor_rank,
        rnk.rnk
    FROM 
        MovieStats ms
    JOIN (
        SELECT 
            production_year,
            DENSE_RANK() OVER (ORDER BY total_movies DESC) AS rnk
        FROM 
            MovieStats
    ) rnk ON ms.production_year = rnk.production_year
)
SELECT 
    r.production_year,
    r.total_actors,
    r.total_movies,
    r.avg_actor_rank,
    COALESCE(p.info, 'No additional info') AS additional_info,
    CASE 
        WHEN r.total_movies = 0 THEN 'No movies found'
        ELSE 'Movies available'
    END AS movie_availability,
    rnk.rnk
FROM 
    RankedMovies r
LEFT JOIN 
    (SELECT person_id, STRING_AGG(info, '; ') AS info FROM person_info GROUP BY person_id) p ON r.total_actors = (
        SELECT COUNT(*) 
        FROM cast_info ci 
        WHERE ci.movie_id IN (SELECT movie_id FROM aka_title t WHERE t.production_year = r.production_year)
    )
WHERE 
    r.total_actors > 10 OR r.production_year IS NULL
ORDER BY 
    r.total_movies DESC, r.production_year ASC
LIMIT 50;

-- Explanation of logic:
-- This query uses a CTE to gather information about the actors cast in movies, filtering by production year.
-- It calculates movie and actor statistics. 
-- The selection at the end includes additional information pulled in from person_info.
-- The WHERE clause demonstrates the use of NULL logic and filtering based on the aggregate values. 
-- The CASE statement adds a semantic edge regarding movie availability based on the count of movies found.
