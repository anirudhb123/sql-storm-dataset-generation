
WITH movie_actor_info AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        c.nr_order, 
        p.info AS actor_info 
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
        AND t.production_year BETWEEN 2000 AND 2023
),
keyword_movie_info AS (
    SELECT 
        t.id AS movie_id, 
        k.keyword, 
        t.title AS movie_title
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title t ON mk.movie_id = t.id
    WHERE 
        k.keyword LIKE '%action%'
),
final_benchmark AS (
    SELECT 
        mai.actor_name, 
        mai.movie_title, 
        mai.production_year, 
        mai.nr_order, 
        km.keyword 
    FROM 
        movie_actor_info mai
    JOIN 
        keyword_movie_info km ON mai.movie_title = km.movie_title
)
SELECT 
    actor_name, 
    movie_title, 
    production_year, 
    nr_order, 
    STRING_AGG(keyword, ', ') AS keywords
FROM 
    final_benchmark
GROUP BY 
    actor_name, 
    movie_title, 
    production_year, 
    nr_order
ORDER BY 
    production_year DESC, 
    actor_name;
