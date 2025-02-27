WITH filtered_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id
),
movie_ratings AS (
    SELECT 
        m.id AS movie_id,
        COUNT(ci.person_id) AS cast_count,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS average_roles_played
    FROM 
        complete_cast m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        m.id
),
enriched_movies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.keywords,
        mr.cast_count,
        mr.average_roles_played 
    FROM 
        filtered_movies fm
    JOIN 
        movie_ratings mr ON fm.movie_id = mr.movie_id
),
actor_frequencies AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_per_movie
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.movie_id) > 5
)
SELECT 
    em.title,
    em.production_year,
    em.keywords,
    em.cast_count,
    em.average_roles_played,
    af.actor_name,
    af.movie_count,
    af.avg_role_per_movie
FROM 
    enriched_movies em
JOIN 
    actor_frequencies af ON em.cast_count > 5
ORDER BY 
    em.production_year DESC, em.cast_count DESC;
