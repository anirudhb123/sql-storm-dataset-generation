WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS associated_keyword,
        rt.role AS primary_role,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword, rt.role
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.associated_keyword,
    rm.primary_role,
    rm.cast_count
FROM 
    ranked_movies rm
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
