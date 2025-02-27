
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COALESCE(mci.company_count, 0) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) AS mci ON t.id = mci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, mci.company_count
),
person_roles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
ranked_movies AS (
    SELECT 
        md.*,
        CASE 
            WHEN company_count > 0 THEN 'Produced'
            ELSE 'Not Produced'
        END AS production_status
    FROM 
        movie_details md
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.production_status,
    COALESCE(pr.actor_count, 0) AS actor_count,
    SUM(CASE WHEN pr.role = 'Actor' THEN pr.actor_count ELSE 0 END) OVER (PARTITION BY rm.production_year) AS total_actors_per_year,
    CASE 
        WHEN rm.title_rank IS NULL THEN 'Unknown'
        ELSE CAST(rm.title_rank AS VARCHAR)
    END AS title_rank_display
FROM 
    ranked_movies rm
LEFT JOIN 
    person_roles pr ON rm.title_id = pr.movie_id
WHERE 
    rm.production_year >= 2000
    AND (rm.keywords IS NOT NULL AND array_length(rm.keywords, 1) > 2)
ORDER BY 
    rm.production_year DESC,
    rm.title;
