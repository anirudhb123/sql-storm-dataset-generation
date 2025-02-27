WITH movie_data AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
), 
company_data AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
keyword_data AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT kw.id) AS keyword_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id, 
    md.movie_title, 
    md.production_year,
    md.total_cast,
    md.cast_names,
    co.company_count,
    co.company_names,
    kw.keyword_count,
    kw.keywords
FROM 
    movie_data md
LEFT JOIN 
    company_data co ON md.movie_id = co.movie_id
LEFT JOIN 
    keyword_data kw ON md.movie_id = kw.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;

