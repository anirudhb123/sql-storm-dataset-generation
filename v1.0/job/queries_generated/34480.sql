WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(t2.title, 'N/A') AS linked_title,
        0 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title t2 ON ml.linked_movie_id = t2.id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(t2.title, 'N/A') AS linked_title,
        level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),
cast_with_role AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        role_type r ON c.role_id = r.id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        f.actor_name,
        f.role,
        mh.linked_title,
        f.actor_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_role f ON mh.movie_id = f.movie_id
)
SELECT 
    fm.title AS movie_title,
    fm.production_year,
    STRING_AGG(DISTINCT fm.actor_name || ' (' || fm.role || ')', ', ') AS actors,
    COUNT(DISTINCT fm.linked_title) AS linked_titles_count,
    CASE 
        WHEN COUNT(DISTINCT fm.linked_title) > 5 THEN 'Highly Linked'
        WHEN COUNT(DISTINCT fm.linked_title) BETWEEN 3 AND 5 THEN 'Moderately Linked'
        ELSE 'Sparsely Linked'
    END AS linkage_level
FROM 
    filtered_movies fm
WHERE 
    fm.linked_title IS NOT NULL
GROUP BY 
    fm.movie_id, fm.movie_title, fm.production_year
HAVING 
    COUNT(DISTINCT fm.actor_name) > 2
ORDER BY 
    fm.production_year DESC;
