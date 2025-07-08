
WITH movie_actor AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        aka_title AS t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS m
    JOIN 
        keyword AS k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
actor_summary AS (
    SELECT 
        ma.movie_id,
        ma.movie_title,
        ma.production_year,
        ma.actor_name,
        ma.actor_rank,
        COALESCE(mk.keywords, 'No Keywords') AS movie_keywords
    FROM 
        movie_actor AS ma
    LEFT JOIN 
        movie_keywords AS mk ON ma.movie_id = mk.movie_id
)
SELECT 
    asum.movie_title,
    asum.production_year,
    asum.actor_name,
    asum.actor_rank,
    asum.movie_keywords
FROM 
    actor_summary AS asum
WHERE 
    asum.actor_rank <= 3
ORDER BY 
    asum.production_year DESC, 
    asum.movie_title, 
    asum.actor_rank;
