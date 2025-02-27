
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(CONCAT(a.name, ' (', ct.kind, ')') ORDER BY a.name) AS cast_information
    FROM
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
    HAVING 
        COUNT(DISTINCT k.id) > 1
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name ORDER BY cn.name) AS company_names,
        STRING_AGG(ct.kind ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FinalBenchmark AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.cast_information,
        cd.company_names,
        cd.company_types
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    movie_keyword,
    cast_information,
    COALESCE(company_names, 'No companies listed') AS company_names,
    COALESCE(company_types, 'No types available') AS company_types
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, movie_title;
