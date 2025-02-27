WITH RECURSIVE actor_movies AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ra.rank,
        title.title AS movie_title,
        COALESCE(aka.name, 'Unknown') AS actor_name
    FROM 
        cast_info ca
    JOIN 
        aka_name aka ON ca.person_id = aka.person_id
    JOIN 
        title ON ca.movie_id = title.id
    JOIN 
        (SELECT id, ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY nr_order) AS rank
         FROM cast_info) ra ON ca.id = ra.id
    
    UNION ALL

    SELECT 
        cm.person_id,
        cm.movie_id,
        ra.rank,
        title.title AS movie_title,
        COALESCE(aka.name, 'Unknown') AS actor_name
    FROM 
        movie_companies cm
    JOIN 
        cast_info ca ON cm.movie_id = ca.movie_id
    JOIN 
        title ON cm.movie_id = title.id
    LEFT JOIN 
        aka_name aka ON ca.person_id = aka.person_id
    JOIN 
        (SELECT id, ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY note) AS rank
         FROM cast_info) ra ON ca.id = ra.id
    WHERE 
        cm.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
)

SELECT 
    am.actor_name,
    am.movie_title,
    am.rank,
    COUNT(DISTINCT am.movie_id) OVER (PARTITION BY am.actor_name) AS movie_count,
    MAX(title.production_year) OVER (PARTITION BY am.actor_name) AS latest_movie_year
FROM 
    actor_movies am
JOIN 
    movie_info mi ON am.movie_id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
    AND mi.info IS NOT NULL
ORDER BY 
    movie_count DESC, 
    am.actor_name;

-- Generate a comparative report of actor participation based on the number of unique movies they have been involved in, 
-- with their latest movie year and sorted by movie count in descending order.
