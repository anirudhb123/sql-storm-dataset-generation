WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        t.title AS movie_title,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        t.id, t.title
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.cast_count,
    ms.aka_names,
    cs.companies,
    cs.company_types,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.id) AS info_count
FROM 
    MovieStats ms
JOIN 
    CompanyStats cs ON ms.movie_title = cs.movie_title
JOIN 
    title t ON ms.movie_title = t.title
ORDER BY 
    ms.production_year DESC, ms.cast_count DESC;
