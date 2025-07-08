
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS yearly_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        c.person_id, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    a.name AS actor_name,
    r.movie_id,
    r.title,
    r.production_year,
    r.yearly_rank,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN ac.movie_count > 5 THEN 'Frequent Actor'
        ELSE 'Occasional Actor'
    END AS actor_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    ranked_movies r ON c.movie_id = r.movie_id
LEFT JOIN 
    actor_movie_count ac ON a.person_id = ac.person_id
LEFT JOIN 
    movie_keywords mk ON r.movie_id = mk.movie_id
WHERE 
    r.yearly_rank <= 10
ORDER BY 
    r.production_year DESC, r.yearly_rank;
