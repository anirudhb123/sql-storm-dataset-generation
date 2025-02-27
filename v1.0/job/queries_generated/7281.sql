WITH MovieStats AS (
    SELECT 
        a.id AS akas_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ca.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        aka_name a_name ON a_name.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        a.id, t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ms.akas_id,
    ms.movie_title,
    ms.production_year,
    ms.total_cast,
    ms.cast_names,
    ci.companies,
    ci.company_types,
    COALESCE(ms.keywords, 'No keywords') AS keywords
FROM 
    MovieStats ms
LEFT JOIN 
    CompanyInfo ci ON ms.akas_id = ci.movie_id
WHERE 
    ms.production_year >= 2000
ORDER BY 
    ms.production_year DESC, ms.movie_title;
