WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_type,
        k.keyword AS movie_keyword,
        i.info AS movie_info
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        comp_cast_type c ON ci.person_role_id = c.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN
        info_type i ON mi.info_type_id = i.id
    WHERE 
        t.production_year > 2000
    ORDER BY 
        t.production_year DESC, 
        a.name
)
SELECT 
    movie_title, 
    production_year, 
    actor_name, 
    cast_type, 
    string_agg(movie_keyword, ', ') AS keywords, 
    string_agg(CONCAT(i.info_type_id, ': ', movie_info), ', ') AS info_details
FROM 
    movie_details md
GROUP BY 
    movie_title, 
    production_year, 
    actor_name, 
    cast_type
HAVING 
    COUNT(movie_keyword) > 1
ORDER BY 
    production_year DESC;
