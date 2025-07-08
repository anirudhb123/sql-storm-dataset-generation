
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS production_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.person_role_id = (SELECT id FROM role_type WHERE role = 'Director') 
        AND t.production_year IS NOT NULL
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.director_name,
        ks.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_summary ks ON rm.movie_id = ks.movie_id
    WHERE 
        rm.production_rank <= 5 
)
SELECT 
    md.title,
    md.production_year,
    md.director_name,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.keywords IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title;
