WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS title_rank,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    rt.title,
    rt.production_year,
    rt.actor_count,
    cm.company_name,
    cm.company_type,
    CASE 
        WHEN rt.actor_count > 10 THEN 'Blockbuster'
        WHEN rt.actor_count BETWEEN 5 AND 10 THEN 'Moderate Hit'
        ELSE 'Indie'
    END AS film_category,
    COALESCE(NULLIF(ROUND(AVG(mi.info::numeric), 2), 0), 'No Data') AS avg_info_rating
FROM 
    RankedTitles rt
LEFT JOIN 
    complete_cast cc ON rt.title = cc.id
LEFT JOIN 
    CompanyMovieInfo cm ON cc.movie_id = cm.movie_id
LEFT JOIN 
    movie_info mi ON cc.movie_id = mi.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%rating%')
WHERE 
    rt.title_rank = 1
    AND rt.production_year >= 2000
GROUP BY 
    rt.title, rt.production_year, cm.company_name, cm.company_type
ORDER BY 
    rt.production_year DESC, rt.actor_count DESC;
