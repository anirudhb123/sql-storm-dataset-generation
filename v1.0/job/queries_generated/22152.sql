WITH Recursive MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.title AS parent_movie,
        COALESCE(m.production_year, 'N/A') AS parent_year
    FROM
        aka_title t
    LEFT JOIN
        movie_link ml ON t.id = ml.movie_id
    LEFT JOIN
        title m ON ml.linked_movie_id = m.id
    WHERE
        t.kind_id = (
            SELECT id FROM kind_type WHERE kind = 'movie'
        )

    UNION ALL

    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        m.title AS parent_movie,
        COALESCE(m.production_year, 'N/A') AS parent_year
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        title m ON ml.linked_movie_id = m.id
)

SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(mh.production_year) AS average_year,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movies,
    SUM(CASE 
        WHEN c.note IS NULL THEN 1 
        ELSE 0 
    END) AS null_note_count,
    MAX(mh.production_year) FILTER (WHERE mh.parent_movie IS NOT NULL) AS latest_linked_year,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
FROM
    cast_info c
JOIN
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN
    MovieHierarchy mh ON c.movie_id = mh.movie_id
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name
HAVING
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY
    rank,
    actor_name
LIMIT 10;

-- Edge cases
WITH MovieStats AS (
    SELECT
        title,
        COUNT(m.id) AS total_cast,
        COUNT(DISTINCT mc.id) AS company_count,
        SUM(CASE 
            WHEN mi.info IS NOT NULL THEN 1 
            ELSE 0 
        END) AS info_count
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    GROUP BY
        title
    HAVING
        total_cast IS NOT NULL OR company_count > 2 -- unusual filter condition
)
SELECT
    title,
    total_cast,
    company_count,
    info_count
FROM
    MovieStats
WHERE
    info_count < (SELECT AVG(info_count) FROM MovieStats)
ORDER BY
    company_count DESC
LIMIT 5;
