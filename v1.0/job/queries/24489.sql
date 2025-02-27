WITH RECURSIVE MovieChain AS (
    SELECT 
        mc.movie_id AS initial_movie_id,
        t.title AS initial_title,
        c.name AS company_name,
        1 AS level
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN aka_title t ON mc.movie_id = t.movie_id
    WHERE mc.company_type_id IN (
        SELECT id FROM company_type WHERE kind LIKE 'Production%'
    )
    UNION ALL
    SELECT 
        cct.movie_id,
        t2.title,
        c2.name,
        m.level + 1
    FROM movie_companies cct
    JOIN company_name c2 ON cct.company_id = c2.id
    JOIN aka_title t2 ON cct.movie_id = t2.movie_id
    JOIN MovieChain m ON m.initial_movie_id = cct.movie_id
    WHERE c2.country_code IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        COUNT (*) OVER (PARTITION BY m.production_year) AS movies_per_year
    FROM aka_title m
    WHERE m.production_year BETWEEN 2000 AND 2023
),
HighestRated AS (
    SELECT 
        movie_info.movie_id,
        AVG(CASE WHEN note IS NOT NULL THEN 1 ELSE 0 END) AS average_rating 
    FROM movie_info 
    WHERE note LIKE '%good%'
    GROUP BY movie_info.movie_id
    HAVING AVG(CASE WHEN note IS NOT NULL THEN 1 ELSE 0 END) > 0.5
),

FinalResults AS (
    SELECT 
        f.movie_id,
        f.title,
        COALESCE(mc.company_name, 'Unknown') AS company_name,
        f.movies_per_year,
        hr.average_rating
    FROM FilteredMovies f
    LEFT JOIN MovieChain mc ON f.movie_id = mc.initial_movie_id
    LEFT JOIN HighestRated hr ON f.movie_id = hr.movie_id
)

SELECT * 
FROM FinalResults
WHERE 
    (movies_per_year > 3 OR average_rating IS NOT NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = FinalResults.movie_id 
        AND LOWER(mi.info) LIKE '%bad%'
    )
ORDER BY 
    (COALESCE(movies_per_year, 0) + COALESCE(average_rating, 0) + LENGTH(company_name)) DESC
LIMIT 50;
