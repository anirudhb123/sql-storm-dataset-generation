WITH RECURSIVE movie_hierarchy AS (
    SELECT
        ml.movie_id AS parent_movie_id,
        ml.linked_movie_id AS child_movie_id,
        1 AS depth
    FROM
        movie_link ml
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
    
    UNION ALL
    
    SELECT
        mh.parent_movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.child_movie_id = ml.movie_id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
),
top_movies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM
        title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year
),
cast_summary AS (
    SELECT
        a.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies,
        AVG(t.production_year) AS average_production_year
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        title t ON ci.movie_id = t.id
    WHERE
        a.name IS NOT NULL
    GROUP BY
        a.name
),
keyword_summary AS (
    SELECT
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM
        keyword k
    JOIN
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY
        k.keyword
    HAVING
        COUNT(mk.movie_id) > 5
)
SELECT
    tm.title,
    tm.production_year,
    tm.production_companies,
    cs.actor_name,
    cs.total_movies,
    cs.average_production_year,
    ks.keyword,
    ks.movie_count,
    mh.depth AS sequel_depth
FROM
    top_movies tm
LEFT JOIN
    movie_hierarchy mh ON tm.title = (
        SELECT
            t.title
        FROM
            title t
        WHERE
            t.id = mh.child_movie_id
    )
JOIN
    cast_summary cs ON cs.total_movies > 10
JOIN
    keyword_summary ks ON ks.movie_count > 5
WHERE
    tm.rank <= 10
ORDER BY
    tm.production_companies DESC,
    cs.total_movies DESC,
    ks.movie_count DESC;
