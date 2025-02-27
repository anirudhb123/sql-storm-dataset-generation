WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        mh.level < 5  -- Limit depth of recursion
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast_members,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS ranking
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN
    aka_name a ON c.person_id = a.person_id
WHERE
    mh.production_year IS NOT NULL
GROUP BY
    mh.movie_id, mh.title, mh.production_year
HAVING
    COUNT(DISTINCT c.person_id) > 0
ORDER BY
    mh.production_year DESC, total_cast_members DESC;

WITH movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        AVG(r.rating) AS avg_rating
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        (SELECT movie_id, AVG(rating) as rating FROM reviews GROUP BY movie_id) r ON m.id = r.movie_id
    WHERE
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY
        m.id
)

SELECT 
    md.movie_id,
    md.title,
    md.keywords,
    COALESCE(md.avg_rating, 0) AS avg_rating,
    CASE 
        WHEN COALESCE(md.avg_rating, 0) >= 8 THEN 'Highly Rated'
        WHEN COALESCE(md.avg_rating, 0) BETWEEN 5 AND 8 THEN 'Average Rated'
        ELSE 'Low Rated' 
    END AS rating_category
FROM 
    movie_details md
ORDER BY 
    avg_rating DESC NULLS LAST;
