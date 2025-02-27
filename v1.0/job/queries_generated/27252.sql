WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title t 
    LEFT JOIN 
        aka_name ak ON ak.person_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        cast_info ca ON ca.movie_id = t.id
    GROUP BY 
        t.id
),
ProductionYears AS (
    SELECT 
        production_year,
        SUM(cast_count) AS total_casts,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        production_year
)
SELECT 
    p.production_year,
    p.total_casts,
    p.movie_count,
    p.total_casts / NULLIF(p.movie_count, 0) AS avg_cast_per_movie
FROM 
    ProductionYears p
ORDER BY 
    p.production_year DESC;

This query provides an overview of the average number of cast members per movie, organized by production year. It aggregates data from various tables to collect information on aka names, companies involved in the movie productions, keywords associated with the movies, and the cast information. It uses Common Table Expressions (CTEs) for clarity and modularity in the SQL statement.
