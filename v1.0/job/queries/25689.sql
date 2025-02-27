
WITH movie_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        k.id AS keyword_id
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
actor_names AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        p.gender,
        p.id AS person_id,
        p.imdb_index
    FROM 
        aka_name a
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        p.gender = 'F'
),
movie_cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        r.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
),
complete_movie_data AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        mt.movie_keyword,
        an.actor_id,
        an.name AS actor_name,
        mc.role_name
    FROM 
        movie_titles mt
    JOIN 
        movie_cast mc ON mt.title_id = mc.movie_id
    JOIN 
        actor_names an ON mc.person_id = an.person_id
)
SELECT 
    cmd.title,
    cmd.production_year,
    cmd.movie_keyword,
    COUNT(DISTINCT cmd.actor_name) AS actress_count,
    STRING_AGG(DISTINCT cmd.actor_name, ', ') AS actresses
FROM 
    complete_movie_data cmd
GROUP BY 
    cmd.title,
    cmd.production_year,
    cmd.movie_keyword
HAVING 
    COUNT(DISTINCT cmd.actor_name) > 2
ORDER BY 
    cmd.production_year DESC, cmd.title;
