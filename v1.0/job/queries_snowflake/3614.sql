
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    GROUP BY 
        ca.movie_id, a.name
),
movie_details AS (
    SELECT 
        m.movie_id,
        m.actor_name,
        m.actor_count,
        r.rank
    FROM 
        actor_movie m
    JOIN 
        ranked_movies r ON m.movie_id = r.movie_id
)

SELECT 
    md.movie_id,
    md.actor_name,
    md.actor_count,
    md.rank,
    COALESCE(mi.info, 'No info available') AS movie_info,
    CASE 
        WHEN md.actor_count > 3 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM 
    movie_details md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
WHERE 
    md.rank <= 10
GROUP BY 
    md.movie_id, md.actor_name, md.actor_count, md.rank, mi.info
ORDER BY 
    md.rank, md.actor_count DESC;
