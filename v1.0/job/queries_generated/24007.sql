WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id, 
        a.person_id, 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
DistinctCompanies AS (
    SELECT 
        mc.movie_id, 
        ARRAY_AGG(DISTINCT c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorMovies AS (
    SELECT 
        ci.movie_id, 
        ci.person_id, 
        a.name AS actor_name,
        t.title,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id 
    GROUP BY 
        ci.movie_id, 
        ci.person_id,
        a.name,
        t.title
)
SELECT 
    rt.person_id,
    a.name AS actor_name,
    rt.title,
    rt.production_year,
    dc.company_names,
    am.role_count,
    COALESCE(CASE WHEN rt.rn = 1 THEN 'Latest Title' ELSE 'Earlier Title' END, 'No Title') AS title_status,
    CASE 
        WHEN rt.production_year BETWEEN 2000 AND 2010 THEN 'Millennium'
        ELSE 'Classic' 
    END AS era,
    STRING_AGG(DISTINCT i.info, '; ') AS additional_info
FROM 
    RankedTitles rt
LEFT JOIN 
    DistinctCompanies dc ON rt.title_id = dc.movie_id
LEFT JOIN 
    ActorMovies am ON rt.title_id = am.movie_id AND rt.person_id = am.person_id
LEFT JOIN 
    person_info i ON rt.person_id = i.person_id AND i.info_type_id IS NOT NULL
WHERE 
    rt.rn = 1 OR rt.production_year IS NULL
GROUP BY 
    rt.person_id, 
    rt.title, 
    rt.production_year, 
    dc.company_names, 
    am.role_count
ORDER BY 
    rt.production_year DESC, 
    actor_name;
