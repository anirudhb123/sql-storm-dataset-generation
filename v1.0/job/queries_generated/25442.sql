WITH TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.role) AS cast_roles
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
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
        ti.title_name,
        ti.production_year,
        ti.movie_keyword,
        ci.company_names,
        ci.company_types,
        ti.cast_roles
    FROM 
        TitleInfo ti
    LEFT JOIN 
        CompanyInfo ci ON ti.title_id = ci.movie_id
)
SELECT 
    title_name,
    production_year,
    movie_keyword,
    company_names,
    company_types,
    cast_roles
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, title_name;
