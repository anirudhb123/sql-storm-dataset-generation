
WITH RECURSIVE movie_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ti.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title ti ON ci.movie_id = ti.movie_id
),
ranked_movies AS (
    SELECT
        mc.movie_id,
        mc.movie_title,
        COUNT(mc.actor_name) AS total_actors,
        MAX(mc.actor_order) AS max_actor_order
    FROM 
        movie_cast mc
    GROUP BY 
        mc.movie_id, mc.movie_title
),
movies_with_keywords AS (
    SELECT 
        r.movie_id,
        r.movie_title,
        r.total_actors,
        RANK() OVER (ORDER BY r.total_actors DESC) AS actor_rank,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        ranked_movies r
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        r.movie_id, r.movie_title, r.total_actors
),
movies_with_production_info AS (
    SELECT 
        mw.movie_id,
        mw.movie_title,
        mw.total_actors,
        mw.actor_rank,
        mw.keywords,
        COALESCE(mi.info, 'N/A') AS production_info
    FROM 
        movies_with_keywords mw
    LEFT JOIN 
        movie_info mi ON mw.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Production Year')
)
SELECT 
    m.movie_title,
    m.total_actors,
    m.actor_rank,
    m.keywords,
    m.production_info
FROM 
    movies_with_production_info m
WHERE 
    m.total_actors > 5
ORDER BY 
    m.actor_rank, m.total_actors DESC;
