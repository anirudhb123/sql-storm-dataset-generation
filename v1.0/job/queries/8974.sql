
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count, 
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY t.id, t.title, t.production_year
),
movie_info_agg AS (
    SELECT 
        movie_id, 
        STRING_AGG(info, '; ') AS movie_details
    FROM movie_info
    GROUP BY movie_id
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.cast_count, 
    rm.aka_names, 
    mia.movie_details
FROM ranked_movies rm
LEFT JOIN movie_info_agg mia ON rm.movie_id = mia.movie_id
WHERE rm.production_year BETWEEN 2000 AND 2020
ORDER BY rm.production_year DESC, rm.cast_count DESC
LIMIT 100;
