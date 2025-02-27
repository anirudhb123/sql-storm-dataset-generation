
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY CHAR_LENGTH(t.title)) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        r.role AS actor_role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Production_Year,
    ad.actor_name AS Actor_Name,
    ad.actor_role AS Role,
    mc.companies AS Production_Companies,
    mc.company_types AS Company_Types,
    mk.keywords AS Movie_Keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorDetails ad ON rt.title_id = ad.movie_id
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.title_rank <= 5  
ORDER BY 
    rt.production_year, rt.title;
