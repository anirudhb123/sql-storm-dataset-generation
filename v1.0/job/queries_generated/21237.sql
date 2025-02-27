WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieActors AS (
    SELECT 
        c.movie_id,
        a.name,
        c.role_id,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.note IS NULL OR c.note <> 'suspended'
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.name IS NOT NULL 
        OR ct.kind IS NOT NULL
)
SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Year,
    ma.name AS Actor_Name,
    md.company_name AS Production_Company,
    COUNT(DISTINCT ma.role_id) AS Unique_Roles,
    COUNT(*) FILTER (WHERE ma.actor_rank <= 3) AS Top_3_Actors,
    STRING_AGG(DISTINCT ma.name, ', ') AS Actor_List
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieActors ma ON rt.title = ma.title AND rt.production_year = ma.production_year
LEFT JOIN 
    CompanyData md ON ma.movie_id = md.movie_id
WHERE 
    rt.title IS NOT NULL
    AND (md.company_name IS NOT NULL OR ma.role_id IS NOT NULL)
GROUP BY 
    rt.title, rt.production_year, md.company_name
HAVING 
    COUNT(DISTINCT ma.role_id) > 0
ORDER BY 
    rt.production_year DESC, rt.title;
