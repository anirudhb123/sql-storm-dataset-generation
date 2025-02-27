WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.person_id,
        a.name,
        ca.movie_id,
        RANK() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id
    WHERE 
        a.name IS NOT NULL
),
movie_details AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        m.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        actor_info a ON mk.movie_id = a.movie_id
    JOIN 
        ranked_movies m ON mk.movie_id = m.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.production_year
)
SELECT 
    md.movie_id, 
    md.production_year,
    title,
    actor_names,
    keyword_count,
    COALESCE(NULLIF(md.actor_names[1], ''), 'Unknown Actor') AS first_actor,
    CASE 
        WHEN md.keyword_count >= 5 THEN 'Popular'
        WHEN md.keyword_count BETWEEN 3 AND 4 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS popularity
FROM 
    movie_details md
LEFT JOIN 
    title t ON md.movie_id = t.id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    popularity DESC;
