WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
), 
actor_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c 
    GROUP BY 
        c.movie_id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    ki.keywords,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_companies mc 
     WHERE 
        mc.movie_id = rm.movie_id 
        AND mc.company_type_id IN (1, 2)) AS production_company_count,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = rm.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')) AS budget_info_exists
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_counts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    keyword_info ki ON rm.movie_id = ki.movie_id
WHERE 
    (rm.title_rank <= 10 AND rm.production_year >= 2000) 
    OR (rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
