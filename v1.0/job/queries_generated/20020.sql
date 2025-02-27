WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) as rank,
        COALESCE(k.keyword, 'N/A') as keyword
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        a.kind_id IN (1, 2) AND -- Assuming kind_id 1 = Movie, 2 = TV Show
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.title, a.production_year, k.keyword
),

cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(r.rank) as highest_rank,
        STRING_AGG(DISTINCT CONCAT(n.name, ' (', rt.role, ')'), ', ') AS cast_details
    FROM 
        cast_info c
    JOIN 
        role_type rt ON c.role_id = rt.id
    JOIN 
        name n ON c.person_id = n.id
    JOIN 
        ranked_movies r ON c.movie_id = (SELECT id FROM aka_title WHERE title = r.title AND production_year = r.production_year LIMIT 1)
    GROUP BY 
        c.movie_id
)

SELECT 
    m.title, 
    m.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_details, 'No cast available') AS cast_details,
    CASE 
        WHEN cs.total_cast IS NULL THEN 'No information'
        WHEN cs.total_cast = 0 THEN 'Empty Cast'
        ELSE 'Cast included'
    END AS cast_status
FROM 
    ranked_movies m
LEFT JOIN 
    cast_summary cs ON m.id = cs.movie_id
ORDER BY 
    m.production_year DESC, m.rank;

-- Including a bizarre semantic corner case:
SELECT 
    COALESCE(NULLIF(rt.role, 'Extra'), 'Not an Extra') AS adjusted_role,
    COUNT(DISTINCT c.person_id) AS actors_count
FROM 
    cast_info c
JOIN 
    role_type rt ON c.role_id = rt.id
GROUP BY 
    adjusted_role
HAVING 
    adjusted_role IS NOT NULL AND 
    (COUNT(DISTINCT c.person_id) > 0 OR adjusted_role LIKE '%Actor%')
ORDER BY 
    actors_count DESC
LIMIT 10;
