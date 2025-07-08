
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    ak.name AS actor_name,
    t.title,
    rt.production_year,
    ct.company_name,
    ct.company_type,
    mi.movie_info,
    COUNT(ci.id) AS total_cast,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_role_order
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    RankedTitles rt ON t.id = rt.title_id
LEFT JOIN 
    CompanyDetails ct ON t.id = ct.movie_id
LEFT JOIN 
    MovieInfo mi ON t.id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
    AND rt.title_rank <= 5
GROUP BY 
    ak.name, t.title, rt.production_year, ct.company_name, ct.company_type, mi.movie_info
HAVING 
    COUNT(ci.id) > 2
ORDER BY 
    rt.production_year DESC, ak.name;
