WITH movie_years AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
cast_details AS (
    SELECT 
        ca.movie_id,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(*) OVER (PARTITION BY ca.movie_id) AS actor_count
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name a ON ca.person_id = a.person_id
    LEFT JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        ca.movie_id, a.name
)
SELECT 
    m.movie_title,
    m.production_year,
    cd.actor_name,
    cd.roles,
    cd.actor_count,
    CASE 
        WHEN cd.actor_count > 5 THEN 'Ensemble'
        ELSE 'Small Cast'
    END AS cast_type
FROM 
    movie_years m
JOIN 
    cast_details cd ON m.movie_title = cd.movie_id
WHERE 
    m.movie_rank <= 10
ORDER BY 
    m.production_year DESC, cd.actor_count DESC
UNION ALL
SELECT 
    CONCAT('Title: ', COALESCE(t.title, 'N/A')),
    t.production_year,
    'N/A',
    'N/A',
    0,
    'No Cast'
FROM 
    title t
LEFT JOIN 
    movie_years my ON t.title = my.movie_title
WHERE 
    my.movie_title IS NULL
ORDER BY 
    production_year DESC;
