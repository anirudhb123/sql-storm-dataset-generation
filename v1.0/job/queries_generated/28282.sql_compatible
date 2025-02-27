
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank,
        t.id AS movie_id
    FROM
        title t
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year >= 2000
        AND a.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
custom_movie_info AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT i.info, '; ') AS additional_info
    FROM 
        movie_info mi
    JOIN 
        info_type i ON mi.info_type_id = i.id
    WHERE 
        i.info ILIKE '%award%'
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.actor_rank,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(cmi.additional_info, 'No Additional Info') AS additional_movie_info
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    custom_movie_info cmi ON rm.movie_id = cmi.movie_id
WHERE 
    rm.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.title;
