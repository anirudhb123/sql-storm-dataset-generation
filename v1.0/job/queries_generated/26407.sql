WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        p.gender AS actor_gender,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year, a.name, p.gender
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.actor_gender,
    md.keywords,
    md.company_types,
    COUNT(*) OVER() AS total_movies
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC
LIMIT 50 OFFSET 0;

This SQL query retrieves movie titles, their production years, actor names, genders, associated keywords, and company types from the specified tables while demonstrating complex aggregations and joins for string processing benchmarking. The results are limited to movies produced between 2000 and 2023, sorted by year and title, and includes an overall count of the total movies retrieved.
