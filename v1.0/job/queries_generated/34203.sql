WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mct.movie_id,
        1 AS level,
        t.title,
        t.production_year,
        string_agg(cn.name, ', ') AS companies
    FROM
        movie_companies mct
    JOIN
        aka_title t ON mct.movie_id = t.movie_id
    JOIN
        company_name cn ON mct.company_id = cn.id
    GROUP BY
        mct.movie_id, t.title, t.production_year

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        mh.level + 1 AS level,
        mt.title,
        mt.production_year,
        mh.companies
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.companies,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(cc.status_id) AS avg_status,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM
    movie_hierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE
    mh.level <= 2 AND 
    (mh.production_year IS NULL OR mh.production_year > 2000) -- filtering for recent movies
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.companies
ORDER BY
    mh.production_year DESC, cast_count DESC;
