WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.production_year IS NOT NULL
        AND a.title IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
), 

CastData AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(CASE WHEN r.role = 'Director' THEN ci.person_id END) AS director_id
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
), 

MovieDirector AS (
    SELECT 
        rm.title,
        rm.production_year,
        c.actor_count,
        (SELECT name FROM name n WHERE n.imdb_id = c.director_id) AS director_name
    FROM 
        RankedMovies rm
    JOIN 
        CastData c ON rm.id = c.movie_id
    WHERE 
        c.actor_count > 1
        AND rm.year_rank < 3
)

SELECT 
    md.title AS "Movie Title",
    md.production_year AS "Year",
    md.actor_count AS "Actor Count",
    COALESCE(md.director_name, 'No Director') AS "Director"
FROM 
    MovieDirector md
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC
LIMIT 10;

-- Edge Cases Considered
-- 1. COALESCE handles NULL director names by replacing them with 'No Director'
-- 2. The ROW_NUMBER function partitions by year, demonstrating performance with window functions.
-- 3. The LEFT JOINs ensure that all movies are represented even if there are no actors or keywords associated with them.
