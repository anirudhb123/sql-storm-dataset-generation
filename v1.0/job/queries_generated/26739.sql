WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kt.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kt ON kt.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
person_cast AS (
    SELECT 
        ci.movie_id,
        GROUP_CONCAT(DISTINCT ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    pc.cast_names
FROM 
    movie_details md
LEFT JOIN 
    person_cast pc ON pc.movie_id = md.movie_id
WHERE 
    md.keywords LIKE '%action%'
ORDER BY 
    md.production_year DESC, md.title;

This SQL query benchmarks string processing by aggregating various data related to movies. It retrieves movie details, including titles, production years, alternate names (aka_names), associated keywords, and the names of cast members. The query filters movies released from the year 2000 onwards and selects those that have the keyword 'action.' It utilizes common table expressions (CTEs) for structured aggregation and ensures the results are ordered by production year and title.
