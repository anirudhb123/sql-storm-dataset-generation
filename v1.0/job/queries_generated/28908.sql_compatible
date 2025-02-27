
WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
        AND ak.name IS NOT NULL
),
highest_ranked_actors AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_name
    FROM 
        ranked_movies
    WHERE 
        actor_rank = 1
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        COUNT(DISTINCT kw.id) AS num_keywords,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keyword_list,
        STRING_AGG(DISTINCT cm.kind, ', ') AS company_types
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mw ON m.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    LEFT JOIN 
        company_type cm ON mc.company_type_id = cm.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title
)
SELECT 
    h.movie_title,
    h.production_year,
    h.actor_name,
    d.num_companies,
    d.num_keywords,
    d.keyword_list,
    d.company_types
FROM 
    highest_ranked_actors h
JOIN 
    movie_details d ON h.movie_title = d.title
ORDER BY 
    h.production_year DESC, 
    h.actor_name;
