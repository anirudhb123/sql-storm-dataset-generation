WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(cast_info_ids.cast_ids, '{}') AS cast_ids,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT nk.name, ', ') FILTER (WHERE nk.name IS NOT NULL) AS notable_actors,
    AVG(NVL(mv.info_length, 0)) AS average_info_length,
    SUM(CASE WHEN cl.kind = 'Producer' THEN 1 ELSE 0 END) AS producer_count,
    MAX(CASE WHEN title.has_subtitle IS TRUE THEN 'Subtitled' ELSE 'Not Subtitled' END) AS subtitle_status
FROM movie_hierarchy m
LEFT JOIN (
    SELECT movie_id, 
           ARRAY_AGG(DISTINCT ci.person_id) AS cast_ids 
    FROM cast_info ci 
    GROUP BY movie_id
) cast_info_ids ON cast_info_ids.movie_id = m.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN (
    SELECT movie_id, 
           LENGTH(info) AS info_length 
    FROM movie_info
    WHERE info_type_id IS NOT NULL
) mv ON mv.movie_id = m.movie_id
LEFT JOIN comp_cast_type cl ON cl.id = (SELECT MIN(person_role_id) FROM cast_info WHERE movie_id = m.movie_id)
LEFT JOIN (
    SELECT title.id AS title_id, 
           CASE WHEN EXISTS(SELECT 1 FROM movie_info mi WHERE mi.movie_id = title.id AND info_type_id = (SELECT id FROM info_type WHERE info = 'subtitles')) 
           THEN TRUE ELSE FALSE END AS has_subtitle
    FROM title
) title ON title.title_id = m.movie_id
LEFT JOIN aka_name nk ON nk.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = m.movie_id)
WHERE m.level <= 3 
GROUP BY m.id, m.title, m.production_year, m.level 
ORDER BY m.production_year DESC, m.title
LIMIT 100
OFFSET 0;
