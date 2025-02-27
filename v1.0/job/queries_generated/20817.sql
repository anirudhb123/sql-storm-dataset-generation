WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(m2.title, 'Not a sequel') AS sequel_title,
        COALESCE(m2.production_year, 0) AS sequel_year,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COALESCE(m2.production_year, 0) DESC) AS seq_rank
    FROM
        aka_title AS m
    LEFT JOIN
        movie_link AS ml ON m.id = ml.movie_id
    LEFT JOIN
        aka_title AS m2 ON ml.linked_movie_id = m2.id
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(m2.title, 'Not a sequel') AS sequel_title,
        COALESCE(m2.production_year, 0) AS sequel_year,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY COALESCE(m2.production_year, 0) DESC) AS seq_rank
    FROM
        MovieHierarchy AS mh
    LEFT JOIN
        movie_link AS ml ON mh.movie_id = ml.movie_id
    LEFT JOIN
        aka_title AS m2 ON ml.linked_movie_id = m2.id
    WHERE
        mh.production_year IS NOT NULL
        AND mh.seq_rank < 5  -- limit to 4 degrees of relationships for hierarchy
),

FilteredMovies AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.sequel_title,
        mh.sequel_year,
        COUNT(ml.linked_movie_id) AS total_linked_movies
    FROM
        MovieHierarchy AS mh
    LEFT JOIN
        movie_link AS ml ON mh.movie_id = ml.movie_id
    GROUP BY
        mh.movie_id, mh.movie_title, mh.production_year, mh.sequel_title, mh.sequel_year
),

TitleAnalysis AS (
    SELECT
        DISTINCT
        ft.movie_title,
        ft.production_year,
        CASE
            WHEN ft.total_linked_movies = 0 THEN 'Solo film'
            WHEN ft.total_linked_movies < 5 THEN 'Limited sequels'
            ELSE 'Franchise!'
        END AS franchise_status,
        COALESCE(SUM(CASE WHEN it.info = 'Budget' THEN mi.info END), 0) AS total_budget,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM
        FilteredMovies AS ft
    LEFT JOIN
        movie_info AS mi ON ft.movie_id = mi.movie_id
    LEFT JOIN
        info_type AS it ON mi.info_type_id = it.id
    LEFT JOIN
        movie_keyword AS mk ON ft.movie_id = mk.movie_id
    LEFT JOIN
        keyword AS kc ON mk.keyword_id = kc.id
    GROUP BY
        ft.movie_title, ft.production_year, ft.total_linked_movies
)

SELECT
    ta.movie_title,
    ta.production_year,
    ta.franchise_status,
    ta.total_budget,
    ta.keyword_count,
    COUNT(DISTINCT cn.company_name) AS company_count
FROM
    TitleAnalysis AS ta
LEFT JOIN
    movie_companies AS mc ON ta.movie_id = mc.movie_id
LEFT JOIN
    company_name AS cn ON mc.company_id = cn.id
WHERE
    ta.total_budget > 0 OR ta.keyword_count > 0  -- filter for significant movies
GROUP BY
    ta.movie_title, ta.production_year, ta.franchise_status, ta.total_budget, ta.keyword_count
HAVING
    COUNT(DISTINCT cn.company_name) > 1  -- focus on movies with more than one company involved
ORDER BY
    ta.total_budget DESC,
    ta.keyword_count DESC
LIMIT 50;  -- limit results for performance benchmarking
