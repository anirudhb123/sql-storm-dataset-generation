WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.movie_id = t.id AND ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.name, k.keyword
),
CompanyStatistics AS (
    SELECT 
        company_name,
        COUNT(DISTINCT movie_id) AS total_movies,
        COUNT(DISTINCT keyword) AS total_keywords
    FROM 
        MovieDetails
    GROUP BY 
        company_name
)
SELECT 
    ms.company_name,
    ms.total_movies,
    ms.total_keywords,
    md.cast_names,
    md.title,
    md.production_year
FROM 
    CompanyStatistics ms
JOIN 
    MovieDetails md ON ms.company_name = md.company_name
ORDER BY 
    ms.total_movies DESC, ms.total_keywords DESC
LIMIT 10;