WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.title, t.production_year, t.id
),
CompanyStatistics AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        MovieDetails m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    cs.company_count,
    cs.company_names
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyStatistics cs ON md.movie_id = cs.movie_id
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
