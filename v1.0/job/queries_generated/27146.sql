WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(CASE WHEN ci.person_role_id IS NOT NULL THEN p.name END) AS cast_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    GROUP BY 
        t.id
),
MovieStatistics AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count,
        AVG(company_count) AS avg_companies,
        AVG(LENGTH(aka_names) - LENGTH(REPLACE(aka_names, ',', '')) + 1) AS avg_aka_names_per_movie,
        AVG(LENGTH(keywords) - LENGTH(REPLACE(keywords, ',', '')) + 1) AS avg_keywords_per_movie,
        AVG(LENGTH(cast_names) - LENGTH(REPLACE(cast_names, ',', '')) + 1) AS avg_cast_per_movie
    FROM 
        MovieDetails
    GROUP BY 
        production_year
)
SELECT 
    ms.production_year,
    ms.movie_count,
    ms.avg_companies,
    ms.avg_aka_names_per_movie,
    ms.avg_keywords_per_movie,
    ms.avg_cast_per_movie
FROM 
    MovieStatistics ms
WHERE 
    ms.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ms.production_year DESC;
