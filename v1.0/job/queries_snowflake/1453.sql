
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
top_ranked AS (
    SELECT 
        title, 
        production_year, 
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank_per_year = 1
),
movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        m.company_type_id,
        ct.kind AS company_type,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        company_name cn ON m.company_id = cn.id
    LEFT JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, m.company_type_id, ct.kind
)
SELECT 
    rd.title,
    rd.production_year,
    rd.cast_count,
    COALESCE(md.company_type, 'Unknown') AS company_type,
    COALESCE(md.company_names, 'No Companies') AS company_names
FROM 
    top_ranked rd
LEFT JOIN 
    movie_details md ON rd.title = md.title AND rd.production_year = md.production_year
ORDER BY 
    rd.production_year DESC, rd.cast_count DESC;
