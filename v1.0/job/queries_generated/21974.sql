WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies_by_year AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank_by_cast = 1
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON k.id = m.keyword_id
    GROUP BY 
        m.movie_id
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        ks.keywords,
        COALESCE(ci.note, 'No Notes') AS cast_notes,
        COALESCE(ci.role_id, 0) AS role_id
    FROM 
        top_movies_by_year tm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.movie_id
    LEFT JOIN 
        keyword_summary ks ON ks.movie_id = tm.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    CASE 
        WHEN md.role_id IS NULL THEN 'Unknown Role'
        WHEN md.role_id = 0 THEN 'No Role Assigned'
        ELSE rt.role 
    END AS role_description,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = md.movie_id AND mc.company_type_id IS NOT NULL) AS company_count,
    AVG(COALESCE(mi.info_length, 0)) AS average_info_length 
FROM 
    movie_details md
LEFT JOIN 
    role_type rt ON rt.id = md.role_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = md.movie_id
GROUP BY 
    md.title, md.production_year, md.keywords, md.role_id
HAVING 
    COUNT(md.keywords) > 0
ORDER BY 
    md.production_year DESC, COUNT(md.keywords) DESC;
