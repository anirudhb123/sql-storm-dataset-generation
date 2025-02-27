WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank
    FROM 
        aka_title a 
    WHERE 
        a.production_year IS NOT NULL
),
movie_cast_info AS (
    SELECT 
        m.id AS movie_id,
        c.person_id,
        r.role
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
indexed_movies AS (
    SELECT 
        m.id,
        m.title,
        COALESCE(mo.info, 'No information available') AS movie_info,
        mm.keyword
    FROM 
        title m
    LEFT JOIN 
        movie_info mo ON m.id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword mm ON mk.keyword_id = mm.id
)
SELECT 
    rm.title,
    rm.production_year,
    COUNT(DISTINCT mci.person_id) AS actor_count,
    STRING_AGG(DISTINCT CONCAT(n.name, ' (', rt.role, ')')) AS actors,
    MAX(CASE WHEN mci.role = 'Director' THEN n.name END) AS director_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE 
        WHEN ci.note IS NULL THEN 0 
        ELSE 1 
    END) AS non_null_cast_notes
FROM 
    ranked_movies rm
JOIN 
    movie_cast_info mci ON rm.id = mci.movie_id
JOIN 
    name n ON mci.person_id = n.id
LEFT JOIN 
    movie_info mi ON rm.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.id = mk.movie_id
LEFT JOIN 
    role_type rt ON mci.role_id = rt.id
GROUP BY 
    rm.id, rm.title, rm.production_year
HAVING 
    COUNT(DISTINCT mci.person_id) > 2
ORDER BY 
    rm.production_year DESC,
    actor_count DESC
LIMIT 50;
