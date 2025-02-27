WITH RecursiveMovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        k.keyword AS movie_keyword,
        c.kind AS cast_type,
        co.name AS company_name
    FROM 
        title t
    JOIN 
        aka_title ak_t ON ak_t.movie_id = t.id
    JOIN 
        aka_name ak ON ak.id = ak_t.id
    JOIN 
        cast_info ci ON ci.movie_id = t.id AND ci.person_id = ak.person_id
    JOIN 
        comp_cast_type c ON c.id = ci.person_role_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name co ON co.id = mc.company_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        k.keyword AS movie_keyword,
        c.kind AS cast_type,
        co.name AS company_name
    FROM 
        title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        aka_name ak ON ak.person_id = cc.subject_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name co ON co.id = mc.company_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT cast_type, ', ') AS cast_types
FROM 
    RecursiveMovieDetails
GROUP BY 
    title, production_year
ORDER BY 
    production_year DESC, title;
