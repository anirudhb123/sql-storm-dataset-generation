
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(MAX(m1.production_year), 0) AS max_production_year,
        COALESCE(MAX(m2.production_year), 0) AS second_max_production_year
    FROM
        aka_title AS m
    LEFT JOIN 
        movie_link AS ml ON ml.movie_id = m.id
    LEFT JOIN 
        aka_title AS m1 ON ml.linked_movie_id = m1.id
    LEFT JOIN 
        movie_link AS ml2 ON ml2.movie_id = ml.linked_movie_id
    LEFT JOIN 
        aka_title AS m2 ON ml2.linked_movie_id = m2.id
    GROUP BY 
        m.id, m.title, m.production_year
), 
filtered_movies AS (
    SELECT 
        mh.*,
        (max_production_year - production_year) AS year_difference,
        CASE 
            WHEN max_production_year = 0 THEN 'No Links'
            ELSE 'Linked'
        END AS link_status
    FROM 
        movie_hierarchy mh
    WHERE 
        production_year >= (
            SELECT 
                AVG(production_year) 
            FROM 
                aka_title
            WHERE 
                production_year IS NOT NULL
        )
), 
actor_data AS (
    SELECT 
        c.movie_id,
        a.id AS actor_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order,
        COUNT(c.person_id) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
), 
keyword_data AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.year_difference,
    ad.actor_id,
    ad.actor_name,
    ad.role_order,
    ad.total_cast,
    kd.keywords,
    CASE 
        WHEN ad.total_cast = 0 THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    filtered_movies AS fm
LEFT JOIN 
    actor_data AS ad ON fm.movie_id = ad.movie_id
LEFT JOIN 
    keyword_data AS kd ON fm.movie_id = kd.movie_id
WHERE 
    fm.link_status = 'Linked'
ORDER BY 
    fm.production_year DESC,
    fm.year_difference DESC,
    ad.role_order
LIMIT 100
OFFSET 0;
