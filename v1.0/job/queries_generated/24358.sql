WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

names_with_roles AS (
    SELECT 
        a.name AS actor_name,
        ct.kind AS role_name,
        ROW_NUMBER() OVER(PARTITION BY a.person_id ORDER BY a.name) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        comp_cast_type ct ON ci.role_id = ct.id
),

movies_with_actors AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT CASE WHEN ci.note IS NOT NULL THEN ci.id END) AS noted_actors
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id
),

keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(r.actor_count, 0) AS total_actors,
    COALESCE(r.noted_actors, 0) AS noted_actors,
    COALESCE(k.keyword_count, 0) AS total_keywords,
    COUNT(nw.actor_name) AS total_roles,
    STRING_AGG(nw.role_name, ', ') AS roles
FROM 
    movies_with_actors r
JOIN 
    ranked_titles rt ON r.title = rt.title 
LEFT JOIN 
    names_with_roles nw ON rt.title_id = nw.actor_name
LEFT JOIN 
    keyword_counts k ON r.movie_id = k.movie_id
WHERE 
    r.actor_count > 0
    AND (r.noted_actors IS NULL OR r.noted_actors < r.actor_count)
GROUP BY 
    m.title, m.production_year
HAVING 
    COUNT(nw.actor_name) > 1
ORDER BY 
    total_keywords DESC, production_year DESC
LIMIT 10;
