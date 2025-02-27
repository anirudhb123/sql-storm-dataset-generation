WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(c.role_id, 'Unknown Role') AS role_id,
    COUNT(DISTINCT c.id) OVER (PARTITION BY ak.id) AS roles_count,
    AVG(mi.rating) AS average_rating,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    MAX(mi.info) FILTER (WHERE it.info = 'Awards') AS awards_info,
    CASE
        WHEN mt.production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(mt.production_year AS TEXT)
    END AS production_year_display
FROM
    aka_name ak
LEFT JOIN
    cast_info c ON ak.person_id = c.person_id
LEFT JOIN
    movie_companies mc ON c.movie_id = mc.movie_id
LEFT JOIN
    company_name co ON mc.company_id = co.id
LEFT JOIN
    movie_info mi ON c.movie_id = mi.movie_id
LEFT JOIN
    title mt ON c.movie_id = mt.id
LEFT JOIN
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN
    info_type it ON mi.info_type_id = it.id
LEFT JOIN
    movie_info_idx mii ON mt.id = mii.movie_id
WHERE
    ak.name IS NOT NULL
    AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    ak.id, mt.title, mt.production_year, c.role_id
ORDER BY 
    roles_count DESC,
    production_year DESC,
    actor_name ASC;
