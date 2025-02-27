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
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit depth to avoid too deep recursion
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT r.role_id) AS role_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN CAST(c.nr_order AS INTEGER) IS NULL THEN 'Unknown Order'
        ELSE CAST(c.nr_order AS TEXT)
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS movie_rank,
    COALESCE(s.name_pcode_nf, 'No PCode') AS name_pcode_nf
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    name s ON a.id = s.id
WHERE 
    m.production_year >= 2000 
    AND (m.title ILIKE '%Action%' OR m.title ILIKE '%Thriller%')
GROUP BY 
    a.name, m.title, m.production_year, c.nr_order, s.name_pcode_nf
HAVING 
    COUNT(DISTINCT r.role_id) > 1  -- More than one role in a movie
ORDER BY 
    movie_rank, m.production_year DESC;
