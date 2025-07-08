
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS cast_name,
        r.role AS person_role,
        LISTAGG(DISTINCT k.keyword, ',') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        role_type r ON ci.person_role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, c.name, r.role
),
BenchmarkResults AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.cast_name,
        md.person_role,
        md.keywords,
        md.company_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.company_count DESC) AS company_rank
    FROM 
        MovieDetails md
)
SELECT 
    production_year,
    COUNT(movie_title) AS movie_count,
    AVG(company_count) AS avg_company_count,
    MAX(company_rank) AS max_rank
FROM 
    BenchmarkResults
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
