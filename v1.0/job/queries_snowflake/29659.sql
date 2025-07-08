WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year BETWEEN 2000 AND 2020
),
actor_movies AS (
    SELECT 
        c.movie_id,
        a.id AS actor_id,
        a.name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        c.person_role_id IN (SELECT id FROM role_type WHERE role = 'actor')
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tt.title,
    tt.production_year,
    am.name AS actor_name,
    km.keyword AS movie_keyword,
    tt.title_rank
FROM 
    ranked_titles tt
JOIN 
    actor_movies am ON am.movie_id = tt.title_id
JOIN 
    keyword_movies km ON km.movie_id = tt.title_id
WHERE 
    tt.title_rank <= 10
ORDER BY 
    tt.production_year DESC, 
    am.name;
