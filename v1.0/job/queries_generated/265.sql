WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rn <= 5
),
company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
keyword_details AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title AS "Movie Title",
    tm.production_year AS "Release Year",
    tm.cast_count AS "Number of Cast Members",
    COALESCE(cd.company_name, 'Unknown') AS "Production Company",
    COALESCE(cd.company_type, 'N/A') AS "Company Type",
    COALESCE(kd.keywords, 'No keywords') AS "Keywords"
FROM 
    top_movies tm
LEFT JOIN 
    company_details cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    keyword_details kd ON tm.movie_id = kd.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
