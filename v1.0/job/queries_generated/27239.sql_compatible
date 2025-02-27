
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        c.kind AS company_type
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
TitleKeywordStats AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keywords) AS total_keywords,
        MIN(production_year) AS earliest_year,
        AVG(LENGTH(movie_title)) AS avg_title_length
    FROM 
        MovieDetails
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    tks.total_keywords,
    tks.earliest_year,
    tks.avg_title_length,
    md.actors,
    md.company_type
FROM 
    MovieDetails md
JOIN 
    TitleKeywordStats tks ON md.movie_id = tks.movie_id
ORDER BY 
    tks.total_keywords DESC,
    md.production_year DESC,
    md.movie_title;
