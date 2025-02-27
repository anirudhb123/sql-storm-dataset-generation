WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT c.name) AS cast_members
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        a.production_year >= 2000 
        AND k.keyword IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyContributions AS (
    SELECT 
        m.movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT co.name) AS companies
    FROM 
        MovieDetails m
    JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.movie_title, m.production_year
),
FinalBenchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.cast_members,
        cc.companies
    FROM 
        MovieDetails md
    JOIN 
        CompanyContributions cc ON md.movie_title = cc.movie_title AND md.production_year = cc.production_year
)
SELECT 
    movie_title,
    production_year,
    cast_members,
    companies
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, movie_title ASC;
