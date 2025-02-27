WITH MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        t.title,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT mc.id) AS total_companies
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id, t.title
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.aka_names,
    cs.companies,
    cs.total_companies
FROM 
    MovieStats ms
LEFT JOIN 
    CompanyStats cs ON ms.title = cs.title
ORDER BY 
    ms.production_year DESC, 
    ms.total_cast DESC;
