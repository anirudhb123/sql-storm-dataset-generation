WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        1 AS depth
    FROM
        movie_link mcl
    JOIN
        title mt ON mcl.movie_id = mt.id
    WHERE
        mt.production_year BETWEEN 2000 AND 2020
    
    UNION ALL
    
    SELECT
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        mh.depth + 1
    FROM
        movie_link mcl
    JOIN
        title mt ON mcl.linked_movie_id = mt.id
    JOIN
        movie_hierarchy mh ON mcl.movie_id = mh.linked_movie_id
)
SELECT
    mh.title,
    mh.production_year,
    mh.depth,
    COALESCE(CAST(COUNT(DISTINCT mc.company_id) AS text), '0') AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    AVG(mi.info::numeric) AS avg_rating
FROM
    movie_hierarchy mh
LEFT JOIN
    movie_companies mc ON mh.linked_movie_id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
LEFT JOIN
    movie_info mi ON mh.linked_movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE
    mh.depth <= 3
GROUP BY
    mh.title, mh.production_year, mh.depth
ORDER BY
    mh.depth DESC, avg_rating DESC
LIMIT 100;

