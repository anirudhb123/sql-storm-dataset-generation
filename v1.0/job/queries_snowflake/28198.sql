
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.id AS aka_id,
        a.name AS aka_name,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        rt.role AS person_role,
        p.name AS person_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
        AND c.country_code = 'USA'
),
AggregatedData AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        LISTAGG(DISTINCT aka_name, ', ') WITHIN GROUP (ORDER BY aka_name) AS aliases,
        LISTAGG(DISTINCT movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords,
        LISTAGG(DISTINCT company_name, ', ') WITHIN GROUP (ORDER BY company_name) AS companies,
        LISTAGG(DISTINCT person_name || ' (' || person_role || ')', ', ') WITHIN GROUP (ORDER BY person_name) AS cast_info
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, movie_title, production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aliases,
    keywords,
    companies,
    cast_info
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, 
    movie_title;
