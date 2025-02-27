
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ct.kind AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Awards' THEN mi.info END) AS awards,
        MAX(CASE WHEN it.info = 'Box office' THEN mi.info END) AS box_office
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mk.keywords,
    mc.actor_name,
    mc.role,
    mi.awards,
    mi.box_office
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    movie_cast mc ON rm.movie_id = mc.movie_id AND mc.actor_rank <= 3
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank_per_year = 1
ORDER BY 
    rm.production_year ASC, rm.title ASC;
