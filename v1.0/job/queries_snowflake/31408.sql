
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3  
),
cast_count AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS number_of_covered_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
highest_paid_cast AS (
    SELECT 
        ci.movie_id,
        MAX(pi.info) AS highest_salary
    FROM 
        cast_info ci
    JOIN 
        person_info pi ON ci.person_id = pi.person_id 
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Salary')
    GROUP BY 
        ci.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cc.number_of_covered_roles, 0) AS cast_count,
        COALESCE(hpc.highest_salary, '0') AS highest_salary,
        RANK() OVER (ORDER BY 
            COALESCE(NULLIF(hpc.highest_salary, '0'), '0')::numeric DESC, 
            COALESCE(cc.number_of_covered_roles, 0) DESC) AS movie_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_count cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        highest_paid_cast hpc ON mh.movie_id = hpc.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.cast_count,
    NULLIF(r.highest_salary, '0')::numeric AS highest_salary,
    r.movie_rank
FROM 
    ranked_movies r
WHERE 
    r.cast_count > 3
    AND r.highest_salary IS NOT NULL
    AND NULLIF(r.highest_salary, '0')::numeric > 1000000  
ORDER BY 
    r.movie_rank;
