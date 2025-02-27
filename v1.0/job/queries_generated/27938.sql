WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT p.name, ', ') AS actors
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.keywords,
    md.companies,
    md.actors,
    CASE 
        WHEN md.production_year < 2010 THEN 'Classic'
        WHEN md.production_year BETWEEN 2010 AND 2020 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC,
    md.movie_title;
