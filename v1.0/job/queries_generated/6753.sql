WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cmp.id) AS company_count,
        STRING_AGG(DISTINCT cmp.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cmp ON mc.company_id = cmp.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    m.cast_count,
    m.keyword_count,
    COALESCE(c.company_count, 0) AS company_count,
    COALESCE(c.companies, 'None') AS companies
FROM 
    MovieStats m
LEFT JOIN 
    CompanyStats c ON m.movie_id = c.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
