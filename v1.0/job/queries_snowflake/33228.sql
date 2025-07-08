
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        LOWER(a.name) LIKE '%smith%' 
    GROUP BY 
        c.person_id
),
ranked_actors AS (
    SELECT 
        ah.person_id,
        ah.movie_count,
        RANK() OVER (ORDER BY ah.movie_count DESC) AS rank
    FROM 
        actor_hierarchy ah
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        ti.title_id,
        ti.title,
        ti.production_year,
        ti.keywords,
        COUNT(ci.id) AS actor_count
    FROM 
        title_info ti
    LEFT JOIN 
        cast_info ci ON ti.title_id = ci.movie_id
    WHERE 
        ti.production_year >= 2000 
    GROUP BY 
        ti.title_id, ti.title, ti.production_year, ti.keywords
    HAVING 
        COUNT(ci.id) > 5
)

SELECT 
    ra.person_id,
    ra.movie_count,
    fm.title,
    fm.production_year,
    fm.keywords
FROM 
    ranked_actors ra
JOIN 
    cast_info ci ON ra.person_id = ci.person_id
JOIN 
    filtered_movies fm ON ci.movie_id = fm.title_id
WHERE 
    ra.rank <= 10 
ORDER BY 
    ra.movie_count DESC, fm.production_year DESC;
