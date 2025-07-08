WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT kc.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword kc ON t.id = kc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_details AS (
    SELECT 
        a.person_id, 
        a.name, 
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.id) AS name_order 
    FROM 
        aka_name a 
    WHERE 
        a.name IS NOT NULL
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        ad.name AS actor_name,
        md.actor_count,
        md.keyword_count,
        RANK() OVER (ORDER BY md.actor_count DESC, md.keyword_count DESC) AS movie_rank
    FROM 
        movie_details md
    LEFT JOIN 
        cast_info ci ON md.movie_id = ci.movie_id
    LEFT JOIN 
        actor_details ad ON ci.person_id = ad.person_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.keyword_count,
    rm.actor_name
FROM 
    ranked_movies rm
WHERE 
    rm.movie_rank <= 10
ORDER BY 
    rm.actor_count DESC, 
    rm.keyword_count DESC;
