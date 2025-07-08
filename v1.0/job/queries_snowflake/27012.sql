
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        p.id AS person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, p.id, a.name
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
)
SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Production_Year,
    ai.actor_name AS Actor_Name,
    ai.movies_count AS Actor_Movies_Count,
    cd.company_name AS Company_Name,
    cd.company_type AS Company_Type
FROM 
    RankedTitles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    ActorInfo ai ON ci.person_id = ai.person_id
JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
WHERE 
    ai.movies_count > 5 
GROUP BY 
    rt.title, rt.production_year, ai.actor_name, ai.movies_count, cd.company_name, cd.company_type
ORDER BY 
    rt.production_year DESC, 
    ai.movies_count DESC;
