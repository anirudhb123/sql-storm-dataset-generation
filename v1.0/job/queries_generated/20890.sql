WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, ml.linked_movie_id
    FROM aka_title mt
    LEFT JOIN movie_link ml ON mt.id = ml.movie_id
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT mh.movie_id, mt.title, mt.production_year, ml.linked_movie_id
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)

, role_distribution AS (
    SELECT 
        ci.role_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(CASE WHEN ci.note IS NOT NULL THEN 1 END) AS roles_with_notes,
        AVG(COALESCE(LENGTH(ci.note), 0)) AS avg_note_length
    FROM cast_info ci
    JOIN aka_name c ON ci.person_id = c.person_id
    GROUP BY ci.role_id
)

, movie_keywords AS (
    SELECT 
        mt.production_year,
        STRING_AGG(mk.keyword, ', ') AS keywords,
        COUNT(DISTINCT mk.id) AS keyword_count
    FROM aka_title mt
    JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.production_year
)

SELECT 
    mh.title,
    mh.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rd.role_id IS NOT NULL THEN 'Role Exists' 
        ELSE 'No Role' 
    END AS role_status,
    rd.total_cast AS total_cast_members,
    rd.roles_with_notes,
    rd.avg_note_length,
    (SELECT COUNT(DISTINCT person_id) FROM cast_info ci WHERE ci.movie_id = mh.movie_id) AS unique_cast_count,
    (SELECT COUNT(DISTINCT movie_id) FROM movie_link ml WHERE ml.linked_movie_id = mh.movie_id) AS linked_movies_count
FROM movie_hierarchy mh
LEFT JOIN movie_keywords mk ON mh.production_year = mk.production_year
LEFT JOIN role_distribution rd ON rd.role_id = (SELECT role_id FROM cast_info WHERE movie_id = mh.movie_id LIMIT 1)
WHERE mh.production_year BETWEEN 2000 AND 2023
ORDER BY mh.production_year DESC, mh.title
LIMIT 100;

-- The above query provides a detailed insight into movies produced within a specified year range, including linked movies,
-- role distribution statistics, and keyword collection while gracefully handling NULL cases and calculating aggregates.
