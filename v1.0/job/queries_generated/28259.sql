WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanyInfo AS (
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
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
FinalOutput AS (
    SELECT 
        a.actor_name,
        a.movie_title,
        a.production_year,
        mc.company_name,
        mc.company_type,
        k.keyword,
        rt.title_rank
    FROM 
        ActorMovieInfo a
    LEFT JOIN 
        MovieCompanyInfo mc ON a.movie_title = mc.movie_id
    LEFT JOIN 
        KeywordInfo k ON a.movie_title = k.movie_id
    LEFT JOIN 
        RankedTitles rt ON a.movie_title = rt.title_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    ORDER BY 
        a.actor_name, a.production_year DESC, rt.title_rank
)

SELECT 
    actor_name,
    movie_title,
    production_year,
    company_name,
    company_type,
    STRING_AGG(keyword, ', ') AS keywords
FROM 
    FinalOutput
GROUP BY 
    actor_name, movie_title, production_year, company_name, company_type
ORDER BY 
    actor_name;
