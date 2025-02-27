WITH Recursive CastHierarchy AS (
    SELECT
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        ro.role,
        1 AS level
    FROM
        cast_info c
    JOIN role_type ro ON c.role_id = ro.id
    WHERE
        c.nr_order IS NOT NULL
    
    UNION ALL
    
    SELECT
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        ro.role,
        ch.level + 1
    FROM
        cast_info c
    JOIN role_type ro ON c.role_id = ro.id
    JOIN CastHierarchy ch ON c.person_id = ch.person_id
    WHERE
        c.nr_order < ch.nr_order
)

SELECT
    ak.name AS actor_name,
    count(*) AS total_movies,
    AVG(m.production_year) AS avg_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT CASE WHEN m.production_year = MAX(m.production_year) THEN m.title END) OVER(PARTITION BY ak.person_id) AS recent_title_count,
    CASE WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = m.id AND mi.info_type_id IN (SELECT it.id FROM info_type it WHERE it.info = 'Budget')) THEN 'Has Budget Info' ELSE 'No Budget Info' END AS budget_info
FROM
    aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title at ON ci.movie_id = at.movie_id
JOIN title m ON at.movie_id = m.id
LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
LEFT JOIN movie_companies mc ON m.id = mc.movie_id
LEFT JOIN company_name co ON mc.company_id = co.id
WHERE
    ak.name IS NOT NULL 
    AND (ak.name ILIKE '%Smith%' OR ak.name ILIKE '%Johnson%')
    AND m.production_year >= 2000
GROUP BY
    ak.id
HAVING
    total_movies > 5
ORDER BY
    avg_year DESC
LIMIT 10;
