WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_year
    FROM 
        aka_title at 
    WHERE 
        at.production_year IS NOT NULL
),
company_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
actors_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
full_movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cm.company_count, 0) AS company_count,
        COALESCE(ar.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords_list, 'None') AS keywords
    FROM 
        title t
    LEFT JOIN 
        company_movies cm ON t.id = cm.movie_id
    LEFT JOIN 
        actors_roles ar ON t.id = ar.movie_id
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
)
SELECT 
    fmd.movie_id,
    fmd.title,
    fmd.production_year,
    fmd.company_count,
    fmd.actor_count,
    fmd.keywords,
    rt.rank_year
FROM 
    full_movie_data fmd
JOIN 
    ranked_titles rt ON fmd.production_year = rt.production_year
WHERE 
    fmd.company_count > 1
    AND fmd.actor_count > 5
ORDER BY 
    fmd.production_year DESC, 
    fmd.title;
