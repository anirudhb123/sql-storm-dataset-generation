WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        CONCAT(m.title, ' (sequel)') AS title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Limit recursion depth to prevent excessive iterations
)
SELECT 
    CONCAT(a.name, ' played as ', r.role) AS Actor_Role,
    m.title AS Movie_Title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS Number_of_Actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS Keywords
FROM 
    MovieHierarchy m 
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = c.person_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.name, r.role, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > (
        SELECT 
            AVG(actor_count) 
        FROM (
            SELECT 
                COUNT(DISTINCT ci.person_id) AS actor_count
            FROM 
                aka_title mt
            JOIN 
                cast_info ci ON mt.id = ci.movie_id
            GROUP BY 
                mt.id
        ) AS subquery
    )
ORDER BY 
    m.production_year DESC, 
    Number_of_Actors DESC
LIMIT 50;
