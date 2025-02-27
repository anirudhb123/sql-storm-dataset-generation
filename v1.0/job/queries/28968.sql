WITH movie_ratings AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MAX(t.production_year) AS production_year,
        CASE 
            WHEN MAX(t.production_year) >= 2000 THEN 'Modern'
            WHEN MAX(t.production_year) BETWEEN 1980 AND 1999 THEN 'Classic'
            ELSE 'Vintage'
        END AS era
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
combined_results AS (
    SELECT 
        mr.movie_id,
        mr.movie_title,
        mr.cast_count,
        mr.actor_names,
        mr.production_year,
        mr.era,
        kc.keyword_count
    FROM 
        movie_ratings mr
    LEFT JOIN 
        keyword_counts kc ON mr.movie_id = kc.movie_id
)
SELECT 
    movie_id,
    movie_title,
    cast_count,
    actor_names,
    production_year,
    era,
    COALESCE(keyword_count, 0) AS keyword_count
FROM 
    combined_results
ORDER BY 
    production_year DESC, cast_count DESC;
