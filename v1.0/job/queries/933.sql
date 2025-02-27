WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
), 
actor_movie_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        ranked_movies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        ci.person_id
), 
top_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ac.movie_count
    FROM 
        aka_name a
    JOIN 
        actor_movie_count ac ON a.person_id = ac.person_id
    WHERE 
        ac.movie_count > 5
), 
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(a.name, ', ') AS actors
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year >= 2000 
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS lead_actor,
    COALESCE(md.actors, 'No Cast') AS full_cast,
    COALESCE(mk.keyword, 'No Keyword') AS movie_keyword
FROM 
    movie_details md
LEFT JOIN 
    top_actors ta ON md.actors LIKE '%' || ta.name || '%'
LEFT JOIN 
    (SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id) mk ON md.movie_id = mk.movie_id
WHERE 
    md.production_year > 2010
ORDER BY 
    md.production_year DESC, 
    md.title
LIMIT 50;
