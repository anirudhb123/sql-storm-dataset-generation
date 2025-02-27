WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(tS.title, '') AS series_title,
        COALESCE(cn.name, 'Unknown Company') AS production_company,
        1 AS depth
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        title tS ON m.episode_of_id = tS.id

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(tS.title, '') AS series_title,
        COALESCE(cn.name, 'Unknown Company') AS production_company,
        mh.depth + 1
    FROM
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.series_title,
    mh.production_company,
    COUNT(DISTINCT ca.person_id) AS total_cast,
    STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
    AVG(DISTINCT mi.info) AS avg_info_length,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_by_cast
FROM
    movie_hierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ca ON ca.movie_id = mh.movie_id
LEFT JOIN
    aka_name p ON ca.person_id = p.person_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE
    mh.production_year IS NOT NULL
    AND (mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office') OR mi.info IS NOT NULL)
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.series_title, mh.production_company
HAVING
    COUNT(DISTINCT ca.person_id) > 0
ORDER BY
    mh.production_year DESC, total_cast DESC;
