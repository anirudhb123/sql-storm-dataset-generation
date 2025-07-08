
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        LISTAGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
CompleteDetails AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.cast_names,
        cd.company_name,
        cd.company_type,
        cd.company_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    cast_names,
    company_name,
    company_type,
    company_count
FROM 
    CompleteDetails
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC,
    movie_title;
