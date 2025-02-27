WITH RECURSIVE movie_hierarchy AS (
    -- CTE to collect all related movies and their details
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROUND(AVG(CAST(ci.nr_order AS FLOAT)), 2) AS avg_cast_order,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM
        aka_title mt
    JOIN
        complete_cast cc ON mt.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        mt.id, mt.title, mt.production_year
    
    UNION ALL
    
    -- Recursive part to navigate through linked movies
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        ROUND(AVG(CAST(ci2.nr_order AS FLOAT)), 2) AS avg_cast_order,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rn
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        complete_cast cc2 ON at.id = cc2.movie_id
    JOIN
        cast_info ci2 ON cc2.subject_id = ci2.person_id
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    GROUP BY
        ml.linked_movie_id, at.title, at.production_year
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.avg_cast_order,
    COALESCE(ki.keyword, 'No keywords') AS keyword,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    CASE WHEN mh.production_year < 2000 THEN 'Classic'
         WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
         ELSE 'Recent' END AS era
FROM
    movie_hierarchy mh
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
WHERE
    mh.avg_cast_order IS NOT NULL
    AND mh.rn <= 5  -- Display only first 5 movies per production year
ORDER BY
    mh.production_year DESC, mh.title;

This SQL query is designed for performance benchmarking and uses an elaborate structure including a recursive CTE to capture hierarchical movie relationships, outer joins to link related data, window functions to calculate averages and rank rows, and complex predicates to differentiate movie eras based on the production year. It includes logic to handle NULL values with `COALESCE` and limits the output to the top 5 movies in each production year.
