WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title t
    JOIN title m ON t.movie_id = m.id
    WHERE
        m.production_year > 2000
    
    UNION ALL
    
    SELECT
        mh.movie_id,
        CONCAT(mh.title, ' | Sequel'),
        mh.production_year,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
    WHERE
        mh.depth < 3
),
TopMovies AS (
    SELECT
        mh.title,
        mh.production_year,
        COUNT(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 END) AS company_count
    FROM
        MovieHierarchy mh
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY
        mh.title, mh.production_year
    HAVING
        COUNT(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 END) > 1
),
TopDirectors AS (
    SELECT
        na.name AS director_name,
        COUNT(CAST(i.info AS INTEGER)) AS movie_count
    FROM
        person_info i
    JOIN aka_name na ON i.person_id = na.person_id
    JOIN cast_info ci ON na.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    WHERE
        i.info_type_id = (SELECT id FROM info_type WHERE info='director') 
        AND t.production_year > 2000
    GROUP BY
        na.name
    HAVING
        COUNT(ci.movie_id) > 5
),
MoviesWithKeyword AS (
    SELECT
        m.title,
        k.keyword
    FROM
        title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword LIKE 'Action%'
)
SELECT
    tm.title AS movie_title,
    tm.production_year,
    td.director_name,
    COALESCE(mw.keyword, 'No Keywords') AS movie_keyword,
    ROW_NUMBER() OVER (PARTITION BY tm.production_year ORDER BY tm.company_count DESC) AS rank
FROM
    TopMovies tm
LEFT JOIN
    TopDirectors td ON tm.title = td.director_name
LEFT JOIN
    MoviesWithKeyword mw ON tm.title = mw.title
ORDER BY
    tm.production_year DESC,
    rank ASC;
