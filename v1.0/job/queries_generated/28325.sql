WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT CONCAT(aka.name, ' (', r.role, ')') ORDER BY aka.name SEPARATOR ', ') AS cast_details,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000 AND
        a.production_year <= 2023
    GROUP BY 
        a.id, a.title, a.production_year, c.name
),
AggregateStats AS (
    SELECT 
        production_year,
        COUNT(movie_title) AS total_movies,
        COUNT(DISTINCT company_name) AS total_companies,
        COUNT(DISTINCT cast_details) AS total_cast
    FROM 
        MovieDetails
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    total_movies,
    total_companies,
    total_cast,
    ROUND(AVG(LENGTH(movie_title)), 2) AS avg_title_length,
    ROUND(AVG(LENGTH(cast_details)), 2) AS avg_cast_length,
    ROUND(AVG(LENGTH(keywords)), 2) AS avg_keywords_length
FROM 
    MovieDetails md
JOIN 
    AggregateStats ag ON md.production_year = ag.production_year
GROUP BY 
    production_year, total_movies, total_companies, total_cast
ORDER BY 
    production_year DESC;
