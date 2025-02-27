WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS keyword,
        c.name AS company_name,
        r.role AS role_type,
        co.name AS country_name
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
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        company_name co ON c.id = co.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword ILIKE '%Action%'
),

AggregatedData AS (
    SELECT 
        md.title_id,
        COUNT(DISTINCT md.role_type) AS unique_roles,
        STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT md.company_name, ', ') AS companies,
        md.production_year
    FROM 
        MovieDetails md
    GROUP BY 
        md.title_id, md.production_year
)

SELECT 
    ad.title_id,
    t.title,
    ad.production_year,
    ad.unique_roles,
    ad.keywords,
    ad.companies
FROM 
    AggregatedData ad
JOIN 
    title t ON ad.title_id = t.id
ORDER BY 
    ad.production_year DESC, ad.unique_roles DESC;
