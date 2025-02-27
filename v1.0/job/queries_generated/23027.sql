WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title AS at
    WHERE 
        at.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        STRING_AGG(DISTINCT at.title, ', ') AS movies,
        COUNT(DISTINCT at.id) AS movie_count
    FROM 
        aka_name AS ak
    JOIN 
        cast_info AS ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title AS at ON ci.movie_id = at.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    WHERE 
        mc.note IS NULL OR mc.note NOT LIKE '%uncredited%'
    GROUP BY 
        mc.movie_id
),
selective_movies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ai.actor_name,
        COALESCE(mci.companies, 'No Companies') AS companies,
        ai.movie_count,
        CASE 
            WHEN ai.movie_count > 5 THEN 'Prolific Actor'
            WHEN ai.movie_count > 0 THEN 'Occasional Actor'
            ELSE 'No Movies'
        END AS actor_status
    FROM 
        ranked_titles AS rt
    LEFT JOIN 
        actor_info AS ai ON rt.title_id = ai.movie_id
    LEFT JOIN 
        movie_company_info AS mci ON rt.title_id = mci.movie_id
    WHERE 
        rt.production_year BETWEEN 2000 AND 2023
    ORDER BY 
        rt.production_year DESC, rt.title ASC
)
SELECT 
    sm.title,
    sm.production_year,
    sm.actor_name,
    sm.companies,
    sm.actor_status,
    CASE 
        WHEN sm.actor_status = 'No Movies' THEN NULL 
        ELSE sm.movie_count 
    END AS actor_movie_count
FROM 
    selective_movies AS sm
WHERE 
    sm.actor_name IS NOT NULL 
    AND (sm.companies IS NOT NULL OR sm.actor_status = 'No Companies')
UNION ALL
SELECT 
    'Unknown Title' AS title,
    NULL AS production_year,
    NULL AS actor_name,
    'No Records' AS companies,
    'N/A' AS actor_status,
    NULL AS actor_movie_count
WHERE 
    NOT EXISTS (SELECT 1 FROM selective_movies)
ORDER BY 
    production_year DESC NULLS LAST, 
    title DESC;
