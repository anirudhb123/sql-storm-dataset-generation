WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        mc.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        mh.movie_id
    FROM movie_link mc
    JOIN title t ON mc.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON mh.movie_id = mc.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COUNT(c.id) AS cast_member_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    MAX(mi.info) AS movie_info_notes,
    CASE 
        WHEN AVG(COALESCE(CAST(c.nr_order AS NUMERIC), 0)) IS NULL THEN 'No Order'
        ELSE 'Average Order: ' || AVG(COALESCE(CAST(c.nr_order AS NUMERIC), 0))::TEXT
    END AS average_cast_order,
    CASE
        WHEN m.production_year < 2010 THEN 'Older'
        ELSE 'Newer'
    END AS production_category,
    COALESCE(SUM(CASE WHEN ck.keyword IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count
FROM MovieHierarchy m
LEFT JOIN complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN cast_info c ON cc.subject_id = c.person_id
LEFT JOIN aka_name a ON c.person_id = a.person_id
LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN keyword ck ON mk.keyword_id = ck.id
GROUP BY m.movie_id, m.title, m.production_year
ORDER BY m.production_year DESC, cast_member_count DESC;
