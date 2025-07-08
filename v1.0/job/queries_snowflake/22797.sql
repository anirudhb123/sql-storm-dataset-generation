
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
),
CompanyAndRoles AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        COALESCE(rt.role, 'Unknown Role') AS role,
        COUNT(DISTINCT ca.person_id) AS num_actors
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ca ON mc.movie_id = ca.movie_id
    LEFT JOIN 
        role_type rt ON ca.role_id = rt.id
    GROUP BY 
        mc.movie_id, cn.name, rt.role
),
MovieInfoWithKeywords AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        mi.info AS movie_info
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mi.movie_id, mi.info
)
SELECT 
    rt.title,
    COALESCE(cry.company_name, 'No Company') AS production_company,
    cry.num_actors,
    LOWER(mikw.keywords) AS keywords_lowercase,
    rt.production_year,
    CASE 
        WHEN rt.title_rank = 1 THEN 'Most Popular Title'
        ELSE 'Regular Title'
    END AS title_status
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyAndRoles cry ON rt.title_id = cry.movie_id
LEFT JOIN 
    MovieInfoWithKeywords mikw ON rt.title_id = mikw.movie_id
WHERE 
    rt.production_year BETWEEN 2000 AND 2023
    AND (cry.num_actors IS NULL OR cry.num_actors > 5)
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
