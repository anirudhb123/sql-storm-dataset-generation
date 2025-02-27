WITH movie_stats AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        EXTRACT(YEAR FROM CURRENT_DATE) - mt.production_year AS age,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%' OR kind LIKE '%Action%')
    GROUP BY 
        mt.id
),
cast_info_enhanced AS (
    SELECT 
        ci.id,
        ci.movie_id,
        ci.person_id,
        ci.person_role_id,
        ci.note,
        ci.nr_order,
        rc.role AS role_name,
        CASE 
            WHEN ci.note IS NULL THEN 'No additional notes'
            ELSE ci.note
        END AS processed_note
    FROM 
        cast_info ci
    JOIN 
        role_type rc ON ci.role_id = rc.id
),
ranked_movies AS (
    SELECT 
        ms.movie_id,
        ms.movie_title,
        ms.age,
        ms.total_cast,
        ms.total_keywords,
        ROW_NUMBER() OVER (ORDER BY ms.age ASC) AS movie_rank,
        RANK() OVER (PARTITION BY ms.age ORDER BY ms.total_cast DESC) AS cast_rank
    FROM 
        movie_stats ms
)
SELECT 
    rm.movie_title,
    rm.age,
    rm.total_cast,
    rm.total_keywords,
    rm.movie_rank,
    rm.cast_rank,
    ci.role_name,
    ci.processed_note
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_info_enhanced ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.total_keywords > 5 
    OR (rm.age < 5 AND rm.total_cast > 10)
ORDER BY 
    rm.movie_rank,
    rm.cast_rank DESC
LIMIT 10;

-- This query captures an interesting scenario where movie stats are calculated, 
-- cast info is processed and enhanced, and final results are ranked and filtered. 
-- It showcases various SQL features including CTEs, window functions, and complex predicates.
