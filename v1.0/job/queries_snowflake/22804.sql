
WITH movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CASE 
            WHEN mt.production_year IS NULL THEN 'Unknown Production Year'
            WHEN mt.production_year < 2000 THEN 'Before 2000'
            ELSE '2000 or Later'
        END AS production_period
    FROM
        aka_title mt
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Production Year'
            WHEN m.production_year < 2000 THEN 'Before 2000'
            ELSE '2000 or Later'
        END AS production_period
    FROM
        movie_link ml
    JOIN
        title m ON ml.linked_movie_id = m.id
    WHERE
        ml.movie_id IN (SELECT movie_id FROM movie_hierarchy)
),
actor_movie AS (
    SELECT DISTINCT
        a.id AS actor_id,
        a.name,
        COALESCE(c.nr_order, 0) AS role_order,
        mh.movie_id,
        mh.title AS movie_title,
        mh.production_year,
        mh.production_period
    FROM
        aka_name a
    LEFT JOIN
        cast_info c ON c.person_id = a.person_id
    JOIN
        movie_hierarchy mh ON c.movie_id = mh.movie_id
),
ranking AS (
    SELECT
        actor_id,
        movie_id,
        movie_title,
        production_year,
        production_period,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY production_year DESC) AS movie_rank
    FROM
        actor_movie
)
SELECT
    r.actor_id,
    r.movie_title,
    r.production_year,
    r.production_period,
    CASE
        WHEN r.movie_rank = 1 THEN 'Latest Movie'
        WHEN r.production_year IS NULL THEN 'Year Unknown'
        ELSE 'Previous Movie'
    END AS movie_status,
    a.name AS actor_name,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM
    ranking r
JOIN
    aka_name a ON r.actor_id = a.id
LEFT JOIN
    movie_keyword mk ON r.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    r.movie_rank <= 3
GROUP BY
    r.actor_id, r.movie_title, r.production_year, r.production_period, a.name, r.movie_rank
HAVING
    COUNT(DISTINCT k.id) > 0 OR (COUNT(DISTINCT k.id) = 0 AND r.movie_rank = 1) 
ORDER BY
    r.actor_id, r.production_year DESC;
