
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(a.name, ', ' ORDER BY a.name) AS actors,
        STRING_AGG(m.name, ', ' ORDER BY m.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),

KeywordStats AS (
    SELECT
        m.id AS movie_id,
        COUNT(mk.id) AS keyword_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        title m ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.actors,
    md.companies,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    COALESCE(ks.keywords, '') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordStats ks ON md.movie_id = ks.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC
LIMIT 100;
