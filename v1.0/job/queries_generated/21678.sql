WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(aka.title, 'Unknown Title') AS aka_title,
        COALESCE(c.name, 'Unknown Cast') AS cast_name,
        1 AS depth
    FROM aka_title AS aka
    JOIN title AS m ON aka.movie_id = m.id
    LEFT JOIN cast_info AS ci ON ci.movie_id = m.id
    LEFT JOIN aka_name AS c ON ci.person_id = c.person_id
    WHERE m.production_year > 2000
    
    UNION ALL
    
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.aka_title,
        mh.cast_name,
        mh.depth + 1
    FROM movie_hierarchy AS mh
    JOIN movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN title AS linked ON ml.linked_movie_id = linked.id
    WHERE mh.depth < 5
)
SELECT
    mh.movie_id,
    mh.movie_title,
    mh.aka_title,
    (SELECT COUNT(*) FROM cast_info WHERE movie_id = mh.movie_id) AS total_cast,
    RANK() OVER (PARTITION BY mh.depth ORDER BY COUNT(mi.info)) AS movie_rank,
    STRING_AGG(DISTINCT COALESCE(CAST(cast_info.note AS TEXT), 'No Note'), '; ') AS cast_notes,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS info_type_count,
    ARRAY_AGG(DISTINCT COALESCE(k.keyword, 'No Keywords') ORDER BY k.keyword) AS keywords
FROM movie_hierarchy AS mh
LEFT JOIN movie_info AS mi ON mh.movie_id = mi.movie_id
LEFT JOIN movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword AS k ON mk.keyword_id = k.id
LEFT JOIN cast_info AS ci ON mh.movie_id = ci.movie_id
WHERE mh.cast_name IS NOT NULL
GROUP BY mh.movie_id, mh.movie_title, mh.aka_title, mh.depth
HAVING COUNT(ci.id) >= 1
ORDER BY mh.depth, movie_rank;

This query creates a recursive Common Table Expression (CTE) to traverse movie links, counting cast members, summarizing notes and aggregating keyword data while applying window functions for ranking. It factors in various conditions and semantics such as NULL handling with `COALESCE`, unique keyword aggregation, and limits the recursion to a maximum depth, illustrating the complexity of relationships within the movie database.
