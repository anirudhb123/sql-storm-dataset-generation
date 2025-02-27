WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS person_role
    FROM 
        title t
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
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    AND 
        k.keyword IS NOT NULL
    AND 
        c.name IS NOT NULL
),
AggregatedMovieData AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
        STRING_AGG(DISTINCT person_name || ' as ' || person_role, ', ') AS cast_details
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, movie_title, production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    keywords,
    production_companies,
    cast_details
FROM 
    AggregatedMovieData
ORDER BY 
    production_year DESC, movie_title;
