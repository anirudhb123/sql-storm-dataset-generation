WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.title AS movie_title,
    mh.production_year AS movie_year,
    COUNT(cc.id) AS num_of_cast_roles,
    AVG(CASE WHEN cc.nota IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY ak.id) AS avg_cast_condition,
    STRING_AGG(DISTINCT it.info, ', ') AS info_type_details,
    COALESCE(NULLIF(mc.note, ''), 'N/A') AS company_note
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    movie_hierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    mh.level <= 2
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, ak.id, mh.title, mh.production_year, mc.note
ORDER BY 
    movie_year DESC, actor_name ASC;

This SQL query employs several advanced features, including:
1. A recursive CTE (`movie_hierarchy`) to derive a hierarchy of movies linked to each other, filtering for those produced after the year 2000.
2. Various joins, including outer joins to incorporate information about companies (`movie_companies`) and information types (`movie_info`).
3. Window functions to calculate the average condition of cast roles.
4. Aggregate functions like `COUNT` and `STRING_AGG` to summarize cast roles and information types, respectively.
5. Use of `COALESCE` and `NULLIF` for handling potential NULL values gracefully in company notes.
6. Filtering and ordering results based on specific criteria.
