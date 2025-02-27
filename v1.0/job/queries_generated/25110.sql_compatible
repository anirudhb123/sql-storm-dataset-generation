
WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.imdb_index AS actor_imdb_index,
        r.role AS actor_role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), 
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        kt.kind AS kind,
        STRING_AGG(DISTINCT ma.actor_name, ', ') AS actor_names
    FROM 
        aka_title m
    JOIN 
        kind_type kt ON m.kind_id = kt.id
    JOIN 
        movie_actors ma ON m.id = ma.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, kt.kind
), 
movie_info_aggregated AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.kind,
        STRING_AGG(mi.info, '; ') AS additional_info
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.kind
)
SELECT 
    mia.movie_id,
    mia.title,
    mia.production_year,
    mia.kind,
    md.actor_names,
    mia.additional_info
FROM 
    movie_info_aggregated mia
JOIN 
    movie_details md ON mia.movie_id = md.movie_id
WHERE 
    mia.production_year >= 2000 
    AND mia.kind IN ('movie', 'tv series')
ORDER BY 
    mia.production_year DESC;
