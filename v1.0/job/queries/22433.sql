
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT kt.id FROM kind_type kt WHERE kt.kind LIKE 'feature%')
),
actor_counts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
highlighted_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        a.movie_count,
        mk.keywords,
        RANK() OVER (PARTITION BY rm.production_year ORDER BY a.movie_count DESC) AS popularity_rank
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_counts a ON a.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = rm.movie_id)
    LEFT JOIN 
        movie_keywords mk ON mk.movie_id = rm.movie_id
    WHERE 
        mk.keywords IS NOT NULL
)
SELECT 
    hm.title,
    hm.production_year,
    hm.movie_count,
    hm.keywords,
    COALESCE(hm.popularity_rank, 999) AS popularity_rank
FROM 
    highlighted_movies hm
WHERE 
    (hm.movie_count > 1 OR hm.keywords LIKE '%drama%')
    AND hm.title NOT LIKE '%unreleased%'
ORDER BY 
    hm.production_year DESC, 
    hm.popularity_rank ASC 
LIMIT 10;
