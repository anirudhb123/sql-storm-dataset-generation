WITH ranked_titles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY LENGTH(a.title) DESC) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.person_id
),
keyword_counts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
top_actors AS (
    SELECT 
        a.person_id,
        a.name,
        counts.movie_count
    FROM 
        aka_name a
    JOIN 
        actor_movie_counts counts ON a.person_id = counts.person_id
    WHERE 
        counts.movie_count >= 5
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword_count
    FROM 
        title t
    JOIN 
        keyword_counts k ON t.id = k.movie_id
    WHERE 
        k.keyword_count >= 3
)
SELECT 
    r.title,
    r.production_year,
    r.kind_id,
    a.name AS actor_name,
    kc.keyword_count
FROM 
    ranked_titles r
JOIN 
    complete_cast cc ON r.title_id = cc.movie_id
JOIN 
    top_actors a ON cc.subject_id = a.person_id
JOIN 
    movie_details md ON r.title_id = md.movie_id
LEFT JOIN 
    keyword_counts kc ON md.movie_id = kc.movie_id
WHERE 
    r.title_rank <= 10
ORDER BY 
    r.production_year DESC, r.title ASC;
