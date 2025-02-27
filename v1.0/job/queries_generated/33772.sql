WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COALESCE(CAST(pk.keywords AS TEXT), 'No Keywords') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mh.production_year DESC) AS movie_rank,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = mh.movie_id) AS total_cast_members,
    (SELECT COUNT(DISTINCT mk.keyword_id)
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE mk.movie_id = mh.movie_id) AS unique_keywords_count
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT OUTER JOIN (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
) pk ON mh.movie_id = pk.movie_id
WHERE
    ak.name IS NOT NULL
    AND mh.production_year BETWEEN 2000 AND 2023
    AND EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = mh.movie_id
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        AND mi.info IS NOT NULL
    )
ORDER BY
    mh.production_year DESC,
    movie_rank;
