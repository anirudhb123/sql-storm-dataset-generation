WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM cast('2024-10-01' as date)) - t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
        LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
        AND k.keyword LIKE '%action%'
),
recent_cast AS (
    SELECT 
        ci.movie_id,
        array_agg(DISTINCT a.name) AS actors,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
        JOIN aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order IS NOT NULL
    GROUP BY 
        ci.movie_id
),
movies_with_cast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rc.actors,
        rc.cast_count,
        CASE 
            WHEN rc.cast_count > 10 THEN 'Ensemble Cast'
            WHEN rc.cast_count BETWEEN 0 AND 10 THEN 'Small Cast'
            ELSE 'No Cast'
        END AS cast_type
    FROM 
        ranked_movies rm
        LEFT JOIN recent_cast rc ON rm.movie_id = rc.movie_id
)
SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.actors,
    mwc.cast_count,
    mwc.cast_type
FROM 
    movies_with_cast mwc
WHERE 
    mwc.production_year >= (SELECT MAX(production_year) FROM aka_title)
    OR mwc.production_year IS NULL
ORDER BY 
    mwc.production_year DESC NULLS LAST
LIMIT 50;