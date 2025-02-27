WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(r.role_count, 0) AS role_count,
        i.info AS movie_info,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COALESCE(r.role_count, 0) DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS role_count
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) r ON m.id = r.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            STRING_AGG(info, ', ') AS info
        FROM 
            movie_info
        WHERE 
            note IS NOT NULL
        GROUP BY 
            movie_id
    ) i ON m.id = i.movie_id
),
DistinctRoles AS (
    SELECT DISTINCT
        c.role_id,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY COUNT(c.person_id) DESC) AS role_rank
    FROM 
        cast_info c 
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.role_id, c.movie_id, r.role
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    m.movie_info,
    COUNT(DISTINCT r.role_id) AS distinct_roles,
    COUNT(c.person_id) AS total_cast,
    CASE 
        WHEN COUNT(c.person_id) > 10 THEN 'Large Cast'
        WHEN COUNT(c.person_id) BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    MAX(CASE WHEN c.nr_order = 1 THEN p.name END) AS lead_actor,
    MAX(CASE WHEN r.role_rank = 1 THEN r.role END) AS most_common_role
FROM 
    RankedMovies m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name p ON c.person_id = p.person_id
LEFT JOIN 
    DistinctRoles r ON c.movie_id = r.movie_id
WHERE 
    m.rn <= 5
GROUP BY 
    m.movie_id, m.title, m.production_year, m.movie_info
ORDER BY 
    m.production_year DESC, COUNT(c.person_id) DESC
LIMIT 10;
