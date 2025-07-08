
WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        MAX(CASE WHEN ct.kind = 'Production' THEN cn.name END) AS production_company,
        MAX(CASE WHEN ct.kind = 'Distribution' THEN cn.name END) AS distribution_company
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.production_year,
    rt.title,
    cw.person_id AS actor_id,
    cw.role_name,
    mw.keywords,
    cm.production_company,
    cm.distribution_company
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_with_roles cw ON rt.title_id = cw.movie_id AND cw.role_rank = 1
LEFT JOIN 
    movies_with_keywords mw ON rt.title_id = mw.movie_id
LEFT JOIN 
    company_movie_info cm ON rt.title_id = cm.movie_id
WHERE 
    rt.title_rank <= 3 
    AND (cm.production_company IS NULL OR cm.distribution_company IS NOT NULL)
ORDER BY 
    rt.production_year DESC, rt.title;
