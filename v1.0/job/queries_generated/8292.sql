WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    GROUP BY 
        t.id, t.title, t.production_year, c.name, k.keyword
),
CastInfo AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS unique_cast_count
    FROM 
        cast_info ca
    GROUP BY 
        ca.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS unique_company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.keyword,
    ci.unique_cast_count,
    co.unique_company_count
FROM 
    MovieDetails md
JOIN 
    CastInfo ci ON md.title_id = ci.movie_id
JOIN 
    CompanyInfo co ON md.title_id = co.movie_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, md.title;
