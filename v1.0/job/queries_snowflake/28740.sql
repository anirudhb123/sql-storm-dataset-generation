
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_info_agg AS (
    SELECT 
        m.movie_id,
        LISTAGG(mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info_details,
        COUNT(mi.note) AS note_count
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    rt.title_rank,
    cd.actor_name,
    cd.role,
    mia.info_details,
    mia.note_count
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    movie_info_agg mia ON rt.title_id = mia.movie_id
WHERE 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, rt.title_rank;
