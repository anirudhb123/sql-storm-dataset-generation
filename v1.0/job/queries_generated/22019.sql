WITH RECURSIVE actor_movies AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COALESCE(t.kind_id, 0) AS kind_id,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
        AND t.production_year >= 2000
    UNION ALL
    SELECT 
        ca.person_id,
        ca.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COALESCE(t.kind_id, 0) AS kind_id,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        actor_movies am
    JOIN 
        cast_info ca ON am.movie_id = ca.movie_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
)
, movie_info_with_keywords AS (
    SELECT 
        m.movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.movie_id, m.title
)
SELECT 
    am.actor_name,
    am.movie_title,
    am.production_year,
    CASE 
        WHEN am.kind_id IN (1, 2) THEN 'Feature/Short' 
        WHEN am.kind_id = 3 THEN 'TV Series'
        ELSE 'Other' 
    END AS movie_type,
    mi.keywords,
    COUNT(mi.keywords) OVER (PARTITION BY am.actor_id) AS keyword_count,
    CASE 
        WHEN COUNT(mi.keywords) OVER (PARTITION BY am.actor_id) = 0 THEN 'No Keywords' 
        ELSE 'Has Keywords' 
    END AS keyword_status,
    CASE 
        WHEN am.movie_rank = 1 THEN 'Latest Movie'
        ELSE NULL 
    END AS latest_movie_flag
FROM 
    actor_movies am
LEFT JOIN 
    movie_info_with_keywords mi ON am.movie_id = mi.movie_id
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM movie_companies mc 
        WHERE mc.movie_id = am.movie_id 
        AND mc.company_id IS NULL
    )
ORDER BY 
    am.actor_name,
    am.production_year DESC
LIMIT 100;
