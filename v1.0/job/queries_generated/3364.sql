WITH movie_ratings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        AVG(COALESCE(r.rating, 0)) AS avg_rating
    FROM 
        title t
    LEFT JOIN 
        rating r ON t.id = r.movie_id
    GROUP BY 
        t.id, t.title
),
person_movie_roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
),
top_movies AS (
    SELECT 
        title_id, 
        AVG(avg_rating) AS average_rating
    FROM 
        movie_ratings
    GROUP BY 
        title_id
    HAVING 
        AVG(avg_rating) > 7.0
)
SELECT 
    m.title,
    COALESCE(p.name, 'Unknown') AS actor_name,
    pm.role,
    pm.role_order,
    CASE 
        WHEN pm.role IS NULL THEN 'No Role Assigned'
        ELSE 'Role Assigned'
    END AS role_status
FROM 
    top_movies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    person_movie_roles pm ON pm.movie_id = cc.movie_id AND pm.person_id = cc.subject_id
LEFT JOIN 
    aka_name p ON p.person_id = pm.person_id
WHERE 
    tm.average_rating > 8.0
ORDER BY 
    tm.average_rating DESC, 
    m.title ASC;
