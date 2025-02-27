WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
),
movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(mi.info, '; ') AS info_summary
    FROM 
        movie_info m
    JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    r.movie_title,
    r.production_year,
    r.actor_name,
    r.actor_rank,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    COALESCE(mis.info_summary, '') AS info_summary
FROM 
    ranked_movies r
LEFT JOIN 
    movie_keyword_counts mkc ON r.movie_id = mkc.movie_id
LEFT JOIN 
    movie_info_summary mis ON r.movie_id = mis.movie_id
ORDER BY 
    r.production_year DESC, 
    r.movie_title;
