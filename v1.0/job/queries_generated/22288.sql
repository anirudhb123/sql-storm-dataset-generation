WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        at.id AS title_id
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
actor_details AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        ci.movie_id,
        at.title,
        COALESCE(ci.note, 'No role assigned') AS role_note
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        ak.name IS NOT NULL
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies_involved,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types 
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
filtered_cast_info AS (
    SELECT 
        ad.actor_name,
        ad.movie_id,
        ad.role_note,
        cti.kind AS role_type
    FROM 
        actor_details ad
    LEFT JOIN 
        comp_cast_type cti ON ad.role_note = cti.id
    WHERE 
        ad.role_note IS NOT NULL
),
movie_performance AS (
    SELECT 
        at.title, 
        cm.companies_involved,
        cast.actor_name,
        cast.role_note,
        cast.role_type,
        COALESCE(s.info, '-') AS movie_info
    FROM 
        ranked_titles rt
    JOIN 
        company_movie_info cm ON rt.title_id = cm.movie_id
    LEFT JOIN 
        filtered_cast_info cast ON cast.movie_id = rt.title_id
    LEFT JOIN 
        movie_info s ON rt.title_id = s.movie_id AND s.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Rating%')
)
SELECT 
    mp.title,
    mp.companies_involved,
    mp.actor_name,
    mp.role_note,
    mp.role_type,
    mp.movie_info
FROM 
    movie_performance mp
WHERE 
    mp.title IS NOT NULL
ORDER BY 
    mp.title ASC, 
    mp.companies_involved DESC NULLS LAST;
