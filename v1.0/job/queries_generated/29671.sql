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

This SQL query does the following:
1. **Movie Stats CTE**: Aggregates data from the `aka_title`, `cast_info`, `movie_keyword`, and `aka_name` tables to compute the total number of cast members, unique actor names associated with each movie, and the count of related keywords for movies produced after the year 2000.
  
2. **Cast Role Distribution CTE**: Counts how many times each type of role has appeared in movies using the `cast_info` and `role_type` tables.

3. **Average Cast Roles CTE**: Calculates the average number of different roles per movie by joining on the cast role distribution.

4. **Final SELECT**: Combines the data from `movie_stats` and `average_cast_roles` to output a comprehensive summary, ordered by the total number of cast members and the average number of roles per movie.
