
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        * 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        m.movie_id, 
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
),
extended_movie_info AS (
    SELECT 
        tm.movie_id, 
        tm.title, 
        tm.production_year, 
        mk.keyword 
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_keywords mk ON tm.movie_id = mk.movie_id
),
final_output AS (
    SELECT 
        e.title, 
        e.production_year, 
        LISTAGG(DISTINCT e.keyword, ', ') WITHIN GROUP (ORDER BY e.keyword) AS keywords, 
        COALESCE(cn.name, 'Unknown') AS company_name,
        COUNT(DISTINCT p.id) AS actor_count
    FROM 
        extended_movie_info e
    LEFT JOIN 
        movie_companies mc ON e.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON e.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        e.title, e.production_year, cn.name
)
SELECT 
    *,
    CASE 
        WHEN actor_count > 0 THEN 'Cast Available'
        ELSE 'No Cast Information'
    END AS cast_status
FROM 
    final_output
ORDER BY 
    production_year DESC, title;
