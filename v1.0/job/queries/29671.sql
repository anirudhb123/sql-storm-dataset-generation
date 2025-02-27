WITH movie_stats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        ARRAY_AGG(DISTINCT a.name) AS unique_actors,
        COUNT(DISTINCT k.keyword) AS related_keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title
),
cast_role_distribution AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info AS c
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
average_cast_roles AS (
    SELECT 
        movie_id,
        AVG(role_count) AS avg_roles_per_movie
    FROM 
        cast_role_distribution
    GROUP BY 
        movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.total_cast_members,
    ms.unique_actors,
    ms.related_keywords,
    ar.avg_roles_per_movie
FROM 
    movie_stats AS ms
JOIN 
    average_cast_roles AS ar ON ms.movie_id = ar.movie_id
ORDER BY 
    ms.total_cast_members DESC, ar.avg_roles_per_movie DESC;