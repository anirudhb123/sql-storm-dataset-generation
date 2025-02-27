WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title AS m
    WHERE
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        m.id,
        m.title,
        m.production_year,
        level + 1
    FROM
        aka_title AS m
    INNER JOIN
        movie_link AS ml ON m.id = ml.movie_id
    INNER JOIN
        movie_hierarchy AS mh ON ml.linked_movie_id = mh.movie_id
),
movie_cast AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ct.kind AS role_type,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM
        cast_info AS ci
    JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        role_type AS ct ON ci.role_id = ct.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(mc.actor_name, 'Unknown') AS top_actor,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(mk.movie_id) OVER () AS total_movies,
    AVG(CASE WHEN mh.production_year IS NOT NULL THEN mh.production_year ELSE NULL END) OVER () AS avg_movie_year
FROM
    movie_hierarchy AS mh
LEFT JOIN
    movie_cast AS mc ON mh.movie_id = mc.movie_id AND mc.actor_rank = 1
LEFT JOIN
    movie_keywords AS mk ON mh.movie_id = mk.movie_id
WHERE
    mh.level < 3 AND
    (mh.production_year > 2015 OR mh.title LIKE 'A%')
ORDER BY
    mh.production_year DESC, mh.movie_title;
