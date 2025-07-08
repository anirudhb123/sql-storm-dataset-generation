
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
),
info_summary AS (
    SELECT 
        m.movie_id,
        MAX(mi.info) AS max_info,
        COUNT(*) AS info_count
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(cs.actor_count, 0) AS total_actors,
    COALESCE(cs.actor_names, '') AS actors_list,
    COALESCE(isum.max_info, 'No Information') AS additional_info,
    isum.info_count,
    r.rank
FROM 
    ranked_movies r
LEFT JOIN 
    aka_title m ON r.title = m.title AND r.production_year = m.production_year
LEFT JOIN 
    cast_summary cs ON m.id = cs.movie_id
LEFT JOIN 
    info_summary isum ON m.id = isum.movie_id
WHERE 
    r.rank <= 5
ORDER BY 
    m.production_year DESC, m.title;
