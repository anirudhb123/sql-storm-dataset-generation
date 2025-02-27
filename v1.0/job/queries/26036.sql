WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ka.person_id) AS actor_count,
        STRING_AGG(DISTINCT ka.name, ', ') AS actors_list
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    JOIN 
        cast_info AS c ON t.movie_id = c.movie_id
    JOIN 
        aka_name AS ka ON c.person_id = ka.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
title_info AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.actor_count,
        rt.actors_list,
        ki.kind AS movie_kind,
        mi.info AS synopsis
    FROM 
        ranked_titles AS rt
    LEFT JOIN 
        kind_type AS ki ON rt.actor_count = ki.id
    LEFT JOIN 
        movie_info AS mi ON rt.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'synopsis')
)
SELECT 
    ti.title,
    ti.production_year,
    ti.actor_count,
    ti.actors_list,
    ti.movie_kind,
    COALESCE(ti.synopsis, 'No synopsis available') AS synopsis
FROM 
    title_info AS ti
ORDER BY 
    ti.production_year DESC, 
    ti.actor_count DESC
LIMIT 10;
