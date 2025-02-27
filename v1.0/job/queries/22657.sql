
WITH RECURSIVE movie_hierarchy AS (
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
    
    UNION ALL
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN movie_hierarchy mh ON mh.linked_movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
),
notable_movies AS (
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(kw.id) AS keyword_count,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis') THEN mi.info END) AS synopsis
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(kw.id) > 5
),
final_output AS (
    
    SELECT 
        nm.title AS notable_title,
        nm.production_year,
        mh.linked_movie_id,
        mh.depth,
        nm.keyword_count,
        COALESCE(nm.synopsis, 'No synopsis available') AS synopsis
    FROM 
        notable_movies nm
    LEFT JOIN 
        movie_hierarchy mh ON nm.movie_id = mh.movie_id
)
SELECT 
    fo.notable_title,
    fo.production_year,
    fo.linked_movie_id,
    fo.depth,
    fo.keyword_count,
    LENGTH(fo.synopsis) AS synopsis_length,
    CASE 
        WHEN fo.keyword_count > 10 THEN 'Highly Keyworded'
        WHEN fo.keyword_count BETWEEN 6 AND 10 THEN 'Moderately Keyworded'
        ELSE 'Sparsely Keyworded'
    END AS keyword_category
FROM 
    final_output fo
WHERE 
    fo.depth IS NOT NULL
ORDER BY 
    fo.production_year DESC,
    fo.keyword_count DESC
LIMIT 50;
