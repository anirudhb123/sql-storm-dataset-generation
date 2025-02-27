WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_performance AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(COALESCE(mi.info_length, 0)) AS avg_info_length
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        movie_info mi ON c.movie_id = mi.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    r.title AS movie_title,
    r.production_year,
    ap.name AS actor_name,
    ap.movie_count,
    ap.avg_info_length,
    CASE 
        WHEN ap.movie_count > 5 THEN 'Prolific Actor'
        WHEN ap.movie_count IS NULL THEN 'No Movies'
        ELSE 'Regular Actor'
    END AS actor_category
FROM 
    ranked_titles r
LEFT JOIN 
    actor_performance ap ON r.title_id IN (
        SELECT 
            c.movie_id
        FROM 
            cast_info c
        WHERE 
            c.movie_id = r.title_id
    )
WHERE 
    r.title_rank <= 3
ORDER BY 
    r.production_year DESC, 
    movie_title;
