
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id 
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(ci.info, 'No Info') AS info
    FROM 
        ranked_movies rm
    LEFT JOIN 
        (SELECT 
            mk.movie_id,
            LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
        FROM 
            movie_keyword mk 
        JOIN 
            keyword k ON mk.keyword_id = k.id 
        GROUP BY 
            mk.movie_id) mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        (SELECT 
            mi.movie_id,
            LISTAGG(mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS info
        FROM 
            movie_info mi 
        GROUP BY 
            mi.movie_id) ci ON rm.movie_id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.info,
    COALESCE(a.name, 'Unknown') AS actor_name
FROM 
    movie_details md
LEFT JOIN 
    (SELECT 
        c.movie_id,
        a.name
     FROM 
        cast_info c 
     JOIN 
        aka_name a ON c.person_id = a.person_id 
     WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%')
    ) a ON md.movie_id = a.movie_id
WHERE 
    md.movie_id IN (SELECT movie_id FROM ranked_movies WHERE rank_per_year <= 5)
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
