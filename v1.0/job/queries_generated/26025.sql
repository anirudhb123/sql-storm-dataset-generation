WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
), 
actor_movie_count AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id
), 
complete_info AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        rc.movie_count,
        ARRAY_AGG(DISTINCT rt.keyword) AS keywords
    FROM 
        ranked_titles rt
    JOIN 
        title t ON rt.title_id = t.id
    JOIN 
        actor_movie_count rc ON t.id IN (
            SELECT movie_id
            FROM cast_info
            WHERE person_id = rc.person_id
        )
    JOIN 
        aka_name a ON a.person_id = rc.person_id
    WHERE 
        rt.keyword_rank <= 5
    GROUP BY 
        a.name, t.title, t.production_year, rc.movie_count
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    movie_count,
    keywords,
    LENGTH(movie_title) AS title_length,
    REPLACE(movie_title, ' ', '_') AS title_snake_case
FROM 
    complete_info
ORDER BY 
    movie_count DESC, production_year DESC;
