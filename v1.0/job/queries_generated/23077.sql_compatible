
WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
actor_movie_count AS (
    SELECT 
        ka.person_id,
        COUNT(c.movie_id) AS movie_count,
        MIN(yk.keyword) AS first_keyword
    FROM 
        aka_name ka
    LEFT JOIN 
        cast_info c ON ka.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword yk ON mk.keyword_id = yk.id
    GROUP BY 
        ka.person_id
),
detailed_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(amc.movie_count, 0) AS actor_count,
        amc.first_keyword
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_movie_count amc ON rm.movie_id = amc.person_id
)

SELECT 
    dm.title,
    dm.production_year,
    dm.cast_count,
    dm.actor_count,
    dm.first_keyword,
    CASE 
        WHEN dm.cast_count > 5 THEN 'Popular'
        WHEN dm.cast_count IS NULL THEN 'Unknown'
        ELSE 'Less Known'
    END AS popularity_category
FROM 
    detailed_movies dm
WHERE 
    dm.first_keyword IS NOT NULL
AND 
    dm.production_year >= 2000
ORDER BY 
    dm.production_year DESC, 
    dm.cast_count DESC NULLS LAST;
