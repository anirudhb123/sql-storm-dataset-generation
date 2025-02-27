WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),

CompanyStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.movie_id
),

CombinedStats AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.total_cast,
        ms.cast_names,
        cs.total_companies,
        cs.company_names,
        ms.keywords
    FROM 
        MovieStats ms
    LEFT JOIN 
        CompanyStats cs ON ms.movie_title = cs.movie_id
)

SELECT 
    production_year,
    COUNT(*) AS total_movies,
    AVG(total_cast::numeric) AS avg_cast_per_movie,
    AVG(total_companies::numeric) AS avg_companies_per_movie,
    STRING_AGG(DISTINCT movie_title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT cast_names, '; ') AS all_cast_names,
    STRING_AGG(DISTINCT keywords, '; ') AS all_keywords
FROM 
    CombinedStats
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
