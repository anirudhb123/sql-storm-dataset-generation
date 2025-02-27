WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
info_summary AS (
    SELECT 
        t.title_id,
        t.movie_title,
        t.production_year,
        COUNT(m.id) AS info_count
    FROM 
        movie_details t
    LEFT JOIN 
        movie_info m ON t.title_id = m.movie_id
    GROUP BY 
        t.title_id, t.movie_title, t.production_year
)
SELECT 
    ds.movie_title,
    ds.production_year,
    ds.keywords,
    ds.companies,
    ds.actors,
    is.info_count
FROM 
    movie_details ds
JOIN 
    info_summary is ON ds.title_id = is.title_id
ORDER BY 
    ds.production_year DESC, ds.movie_title;
