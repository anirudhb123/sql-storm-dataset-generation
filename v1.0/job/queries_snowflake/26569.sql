
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title AS t
    INNER JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    INNER JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    INNER JOIN 
        cast_info AS c ON t.id = c.movie_id
    INNER JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, ak.name
),
top_movies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        actor_count,
        keywords
    FROM 
        ranked_movies
    WHERE 
        rn = 1
    ORDER BY 
        actor_count DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    tm.actor_count,
    tm.keywords,
    ti.info AS additional_info
FROM 
    top_movies AS tm
LEFT JOIN 
    movie_info AS mi ON tm.title = mi.info
LEFT JOIN 
    info_type AS ti ON mi.info_type_id = ti.id
ORDER BY 
    tm.production_year DESC;
