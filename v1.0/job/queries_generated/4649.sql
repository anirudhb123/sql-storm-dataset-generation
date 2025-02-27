WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 3
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        aka_title ak ON tm.movie_id = ak.movie_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(NULLIF(array_to_string(md.aka_names, ', '), ''), 'No Alternate Titles') AS alternate_titles,
    COALESCE(NULLIF(array_to_string(md.company_names, ', '), ''), 'No Companies Involved') AS companies_involved
FROM 
    movie_details md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC;
