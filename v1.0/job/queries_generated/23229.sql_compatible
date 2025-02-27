
WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ca ON mt.movie_id = ca.movie_id
    WHERE 
        mt.production_year IS NOT NULL AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
YearlyCastRank AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        rank_by_cast,
        MAX(cast_count) OVER (PARTITION BY production_year) AS max_cast_count
    FROM 
        RecursiveMovieCTE
), 
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        rank_by_cast,
        CASE 
            WHEN cast_count IS NULL THEN 'No actors' 
            WHEN cast_count < 5 THEN 'Fewer actors' 
            ELSE 'Well cast'
        END AS casting_status
    FROM 
        YearlyCastRank
    WHERE 
        cast_count > 0
)
SELECT 
    pm.movie_id,
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.casting_status,
    (SELECT ARRAY_AGG(DISTINCT cn.name) FROM char_name cn WHERE cn.imdb_id IN (SELECT DISTINCT person_id FROM cast_info ci WHERE ci.movie_id = pm.movie_id)) AS leading_actors,
    COALESCE((
        SELECT COUNT(DISTINCT mc.company_id) 
        FROM movie_companies mc 
        WHERE mc.movie_id = pm.movie_id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind ILIKE '%studio%')
    ), 0) AS studio_count
FROM 
    PopularMovies pm
WHERE 
    pm.casting_status != 'No actors'
ORDER BY 
    pm.production_year DESC, 
    pm.cast_count DESC
LIMIT 100;
