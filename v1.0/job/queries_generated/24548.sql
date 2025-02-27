WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.production_year,
        m.title,
        COALESCE(p.name, 'Unknown') AS director_name,
        1 AS depth
    FROM
        aka_title m
        LEFT JOIN movie_companies mc ON m.id = mc.movie_id
        LEFT JOIN company_name p ON mc.company_id = p.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    WHERE
        m.production_year IS NOT NULL

    UNION ALL
    
    SELECT
        mh.movie_id,
        m.production_year,
        m.title,
        COALESCE(p.name, 'Unknown') AS director_name,
        mh.depth + 1 AS depth
    FROM
        movie_hierarchy mh
        JOIN movie_link ml ON mh.movie_id = ml.movie_id
        JOIN aka_title m ON ml.linked_movie_id = m.id
        LEFT JOIN movie_companies mc ON m.id = mc.movie_id
        LEFT JOIN company_name p ON mc.company_id = p.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    WHERE
        mh.depth < 5  -- Limit the depth to prevent infinite recursion
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.director_name,
    mh.depth,
    COUNT(distinct mc.company_id) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(distinct mc.company_id) DESC) AS year_rank,
    LAG(mh.production_year, 1, NULL) OVER (ORDER BY mh.production_year) AS previous_year
FROM
    movie_hierarchy mh
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
WHERE
    mh.director_name IS NOT NULL OR mh.depth > 1
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.director_name, mh.depth
HAVING
    COUNT(distinct mc.company_id) > 2
ORDER BY
    mh.production_year DESC, 
    year_rank ASC;

