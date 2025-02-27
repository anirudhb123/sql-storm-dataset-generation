WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_details AS (
    SELECT 
        rm.title, 
        rm.production_year,
        ak.name AS actor_name,
        cct.kind AS role_kind,
        CASE 
            WHEN mi.info IS NOT NULL THEN mi.info
            ELSE 'N/A'
        END AS movie_info
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        info_type it ON it.id = (SELECT info_type_id FROM movie_info WHERE movie_id = (SELECT id FROM aka_title WHERE title = rm.title) LIMIT 1)
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = rm.title) AND mi.info_type_id = it.id 
    LEFT JOIN 
        comp_cast_type cct ON ci.person_role_id = cct.id
    WHERE 
        rm.movie_rank <= 5
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.role_kind,
    COALESCE(md.movie_info, 'No information available') AS movie_info
FROM 
    movie_details md
WHERE 
    md.actor_name IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
