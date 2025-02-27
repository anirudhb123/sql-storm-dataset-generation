WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
filtered_actors AS (
    SELECT 
        a.id,
        a.name,
        ac.movie_count
    FROM 
        aka_name a
    JOIN 
        actor_counts ac ON a.person_id = ac.person_id
    WHERE 
        ac.movie_count > 5
)
SELECT 
    f.name AS actor_name,
    r.title AS featured_movie,
    r.production_year,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN f.movie_count > 10 THEN 'Frequent Actor'
        ELSE 'Occasional Actor'
    END AS actor_category
FROM 
    filtered_actors f
LEFT JOIN 
    ranked_movies r ON r.year_rank <= 3
LEFT JOIN (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
) mk ON r.title = mk.movie_id
WHERE 
    f.name IS NOT NULL
ORDER BY 
    r.production_year DESC, f.name;
