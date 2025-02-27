WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        ci.person_id, 
        c.role_id, 
        COUNT(*) AS total_movies, 
        ARRAY_AGG(DISTINCT t.title) AS movie_titles
    FROM 
        cast_info ci
    JOIN 
        role_type c ON ci.role_id = c.id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        ci.person_id, c.role_id
),
null_movie_info AS (
    SELECT 
        mi.movie_id, 
        COUNT(CASE WHEN mi.info IS NULL THEN 1 END) AS null_info_count
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    a.person_id,
    ak.name AS actor_name,
    rt.title AS highest_rated_title,
    rt.production_year,
    ar.total_movies,
    ar.movie_titles,
    nmi.null_info_count,
    COALESCE(nmi.null_info_count, 0) AS adjusted_null_count,
    CASE 
        WHEN rt.title IS NOT NULL AND ar.total_movies > 10 THEN 'Prolific Actor'
        WHEN rt.title IS NULL THEN 'No Title Found'
        ELSE 'Regular Actor'
    END AS actor_type
FROM 
    aka_name ak
LEFT JOIN 
    actor_roles ar ON ak.person_id = ar.person_id
LEFT JOIN 
    ranked_titles rt ON ar.role_id = rt.title_id AND rt.title_rank = 1
LEFT JOIN 
    null_movie_info nmi ON ar.movie_titles[1] IS NOT NULL AND nmi.movie_id = ar.movie_titles[1]
WHERE 
    ak.name IS NOT NULL 
    AND (ar.total_movies > 1 OR rt.production_year < 2000)
ORDER BY 
    adjusted_null_count DESC, 
    ar.total_movies DESC,
    ak.name;
