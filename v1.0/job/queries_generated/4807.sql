WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
top_actors AS (
    SELECT 
        am.person_id,
        am.movie_count
    FROM 
        actor_movie_counts am
    WHERE 
        am.movie_count >= (SELECT AVG(movie_count) FROM actor_movie_counts)
)
SELECT 
    r.actor_name,
    r.movie_title,
    r.production_year,
    COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
    ct.kind AS company_type,
    CASE 
        WHEN r.title_rank = 1 THEN 'Latest Movie'
        ELSE 'Earlier Movie'
    END AS movie_status
FROM 
    ranked_titles r
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = r.aka_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = r.aka_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    top_actors ta ON r.aka_id = ta.person_id
WHERE 
    r.title_rank <= 5
ORDER BY 
    r.actor_name, r.production_year DESC;
