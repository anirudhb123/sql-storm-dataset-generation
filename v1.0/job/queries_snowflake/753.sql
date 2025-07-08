
WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn,
        at.id
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cm.company_count,
    cm.company_names,
    (SELECT 
         COUNT(DISTINCT ci.person_id) 
     FROM 
         cast_info ci 
     WHERE 
         ci.movie_id = rt.id) AS actor_count
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyMovies cm ON rt.id = cm.movie_id
WHERE 
    rt.rn <= 5
GROUP BY 
    rt.title,
    rt.production_year,
    cm.company_count,
    cm.company_names,
    rt.id
ORDER BY 
    rt.production_year DESC, 
    rt.title;
