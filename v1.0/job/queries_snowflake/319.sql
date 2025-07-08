WITH ranked_titles AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
popular_actors AS (
    SELECT 
        a.name,
        am.movie_count
    FROM 
        aka_name a
    JOIN 
        actor_movie_counts am ON a.person_id = am.person_id
    WHERE 
        am.movie_count > (
            SELECT 
                AVG(movie_count)
            FROM 
                actor_movie_counts
        )
),
movies_with_keywords AS (
    SELECT 
        m.id,
        m.title,
        k.keyword
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    pt.title,
    pt.production_year,
    pa.name AS popular_actor,
    mk.keyword
FROM 
    ranked_titles pt
LEFT JOIN 
    movies_with_keywords mk ON pt.id = mk.id
JOIN 
    popular_actors pa ON pa.movie_count = (
        SELECT 
            MAX(movie_count)
        FROM 
            actor_movie_counts
    )
WHERE 
    pt.title_rank <= 5
    AND (mk.keyword IS NULL OR mk.keyword != 'drama')
ORDER BY 
    pt.production_year DESC, pt.title;
