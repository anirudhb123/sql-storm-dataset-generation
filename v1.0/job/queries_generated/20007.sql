WITH RECURSIVE ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.md5sum AS actor_md5,
        COUNT(DISTINCT ci.id) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
movie_information AS (
    SELECT 
        m.movie_id,
        COALESCE(mi.info, 'No additional info') AS extra_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_info m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id, mi.info
),
final_results AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.actor_md5,
        cd.actor_count,
        mi.extra_info,
        mi.keyword_count,
        CASE 
            WHEN mi.keyword_count > 5 THEN 'Diverse'
            WHEN mi.keyword_count BETWEEN 3 AND 5 THEN 'Moderate'
            ELSE 'Sparse'
        END AS keyword_diversity,
        CASE 
            WHEN rm.rank_in_year = 1 THEN 'Premier'
            ELSE 'Regular'
        END AS release_type
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_details cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        movie_information mi ON rm.movie_id = mi.movie_id
    WHERE 
        rm.production_year >= 2000
)
SELECT 
    movie_id,
    title,
    production_year,
    COUNT(*) OVER (PARTITION BY production_year) AS total_movies_in_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS all_actors,
    MAX(actor_md5) AS leading_actor_md5,
    MAX(extra_info) AS detailed_info,
    MAX(keyword_count) AS total_keywords,
    keyword_diversity,
    release_type
FROM 
    final_results
GROUP BY 
    movie_id, title, production_year, keyword_diversity, release_type
ORDER BY 
    production_year DESC,
    title ASC
LIMIT 100;

-- This SQL query achieves the following:
-- Combines multiple complex constructs including CTEs, window functions, and outer joins.
-- Ranks movies, aggregates actor names, counts keywords, and provides a classification on the diversity of keywords.
-- It focuses on movies from 2000 onwards, ensuring that the results are recent and relevant for benchmarking.
-- It also exhibits NULL logic through the COALESCE usage, handling cases where information might be absent.
