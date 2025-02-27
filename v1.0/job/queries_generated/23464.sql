WITH movie_rankings AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        mt.id
),

top_movies AS (
    SELECT 
        *,
        CASE 
            WHEN cast_count IS NULL THEN 'No cast'
            WHEN cast_count >= 5 THEN 'Star-studded'
            ELSE 'Small cast' 
        END AS cast_description
    FROM 
        movie_rankings
    WHERE 
        rn <= 10
),

movie_keywords AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),

final_benchmark AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.actor_names,
        mk.keyword_count,
        tm.cast_description,
        CASE 
            WHEN mk.keyword_count > 10 THEN 'Highly tagged'
            WHEN tm.cast_count >= 5 AND mk.keyword_count < 5 THEN 'Star potential'
            ELSE 'Moderate'
        END AS movie_rating
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_keywords mk ON tm.movie_id = mk.movie_id
)

SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.cast_count,
    fb.actor_names,
    COALESCE(fb.keyword_count, 0) AS keyword_count,
    fb.cast_description,
    fb.movie_rating
FROM 
    final_benchmark fb
WHERE 
    fb.production_year IS NOT NULL
    AND fb.cast_count IS NOT NULL
    AND (fb.movie_rating = 'Star potential' OR fb.movie_rating = 'Highly tagged')
ORDER BY 
    fb.production_year DESC, fb.cast_count DESC;
