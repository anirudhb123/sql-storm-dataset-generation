WITH MovieTitleInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind SEPARATOR ', ') AS company_types,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS actors
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id 
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
AggregatedTitleInfo AS (
    SELECT 
        production_year,
        COUNT(movie_id) AS total_movies,
        COUNT(DISTINCT actors) AS total_actors,
        COUNT(DISTINCT keywords) AS total_keywords,
        GROUP_CONCAT(DISTINCT title ORDER BY title SEPARATOR '; ') AS movie_titles
    FROM 
        MovieTitleInfo
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    total_movies,
    total_actors,
    total_keywords,
    movie_titles
FROM 
    AggregatedTitleInfo
ORDER BY 
    production_year DESC;

