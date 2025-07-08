
WITH movie_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year >= 2000
), movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), movie_info_details AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info LIKE '%Award%' 
    GROUP BY 
        mi.movie_id
)

SELECT 
    a.actor_name,
    a.movie_title,
    a.production_year,
    a.actor_order,
    k.keywords,
    m.info_details
FROM 
    movie_actors a
LEFT JOIN 
    movie_keywords k ON a.movie_id = k.movie_id
LEFT JOIN 
    movie_info_details m ON a.movie_id = m.movie_id
ORDER BY 
    a.production_year DESC, 
    a.actor_order;
