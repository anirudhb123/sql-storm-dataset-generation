WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 3
),
actor_titles AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS rank
    FROM
        aka_name ak
    INNER JOIN cast_info ci ON ak.person_id = ci.person_id
    INNER JOIN aka_title at ON ci.movie_id = at.id
    WHERE
        ak.name IS NOT NULL
),
top_actors AS (
    SELECT
        actor_id,
        name,
        COUNT(DISTINCT rank) AS title_count
    FROM
        actor_titles
    WHERE
        rank <= 5
    GROUP BY
        actor_id, name
    HAVING
        COUNT(DISTINCT rank) >= 3
),
movie_keyword_info AS (
    SELECT
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id, k.keyword
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ta.name AS top_actor,
    mki.keyword, 
    COALESCE(mki.keyword_count, 0) AS keyword_usage
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    top_actors ta ON cc.subject_id = ta.actor_id
LEFT JOIN 
    movie_keyword_info mki ON mh.movie_id = mki.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC, 
    keyword_usage DESC;

