WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        t.id AS root_movie_id
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    
    UNION ALL 
    
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
highest_rated_movies AS (
    SELECT 
        t.id AS movie_id,
        avg(mi.info_type_id) AS average_rating
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        t.id
    HAVING 
        avg(mi.info_type_id) IS NOT NULL
),
cast_with_roles AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
),
complex_query AS (
    SELECT 
        mh.title AS movie_title,
        mh.production_year,
        mw.average_rating,
        cwr.actor_name,
        cwr.actor_role,
        cwr.actor_rank,
        CASE WHEN mw.average_rating IS NULL THEN 'No Rating' ELSE 'Rated' END AS rating_status,
        CASE WHEN mw.average_rating >= 8 THEN 'Highly Rated' ELSE 'Moderate Rated' END AS rating_category
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        highest_rated_movies mw ON mh.movie_id = mw.movie_id
    LEFT JOIN 
        cast_with_roles cwr ON mh.movie_id = cwr.movie_id
)
SELECT 
    DISTINCT movie_title,
    production_year,
    COALESCE(average_rating, 0) AS average_rating,
    STRING_AGG(actor_name || ' as ' || actor_role, ', ' ORDER BY actor_rank) AS cast_list,
    COUNT(actor_name) FILTER (WHERE cwr.actor_role IS NOT NULL) AS total_cast,
    COUNT(DISTINCT CASE WHEN actor_role IS NOT NULL AND actor_role NOT LIKE '%extras%' THEN actor_name END) AS main_cast_count
FROM 
    complex_query 
GROUP BY 
    movie_title, production_year, average_rating
ORDER BY 
    average_rating DESC NULLS LAST, movie_title
FETCH FIRST 10 ROWS ONLY;

