
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title at
    JOIN 
        title t ON at.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        t.title, t.production_year
),
PerformanceBenchmark AS (
    SELECT 
        movie_title,
        production_year,
        aka_names,
        keywords,
        companies
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000
)
SELECT 
    movie_title,
    production_year,
    aka_names,
    keywords,
    companies
FROM 
    PerformanceBenchmark
ORDER BY 
    production_year DESC;
