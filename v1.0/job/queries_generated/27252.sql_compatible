
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
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
        t.id, t.title, t.production_year
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
