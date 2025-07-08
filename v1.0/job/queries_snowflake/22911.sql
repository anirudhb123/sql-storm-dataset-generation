
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorData AS (
    SELECT 
        DISTINCT a.person_id,
        n.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        name n ON n.id = c.person_id
    LEFT JOIN 
        aka_name a ON a.person_id = n.imdb_id
    WHERE 
        a.name IS NOT NULL 
        AND n.gender = 'M' 
    GROUP BY 
        a.person_id, n.name
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mi.info, 'No info') AS movie_info
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            info 
         FROM 
             movie_info 
         WHERE 
             info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')) mi 
         ON mi.movie_id = mc.movie_id
),
LostActors AS (
    SELECT 
        ad.person_id,
        ad.name
    FROM 
        ActorData ad
    LEFT JOIN 
        cast_info c ON c.person_id = ad.person_id
    WHERE 
        c.movie_id IS NULL
)
SELECT 
    rt.title,
    rt.production_year,
    LISTAGG(DISTINCT la.name, ', ') WITHIN GROUP (ORDER BY la.name) AS lost_actors,
    LISTAGG(DISTINCT ci.company_name || ' (' || ci.company_type || '): ' || ci.movie_info, '; ') WITHIN GROUP (ORDER BY ci.company_name) AS companies_info,
    COUNT(DISTINCT ad.person_id) AS total_actors
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyInfo ci ON ci.movie_id = rt.title_id
LEFT JOIN 
    ActorData ad ON ad.movie_count > 5
LEFT JOIN 
    LostActors la ON la.person_id = ad.person_id
WHERE 
    rt.rn = 1
GROUP BY 
    rt.title, rt.production_year
ORDER BY 
    rt.production_year DESC, rt.title;
