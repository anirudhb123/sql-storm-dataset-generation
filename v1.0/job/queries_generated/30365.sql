WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title AS m
    JOIN 
        movie_link AS ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
),
cast_info_with_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS role_count,
        STRING_AGG(DISTINCT ct.kind, ', ') AS roles
    FROM 
        cast_info AS ci
    JOIN 
        comp_cast_type AS ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cwr.role_count,
        cwr.roles,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cwr.role_count DESC) AS role_rank
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        cast_info_with_roles AS cwr ON mh.movie_id = cwr.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.role_count, 0) AS total_roles,
    md.roles,
    CASE 
        WHEN md.role_count IS NULL THEN 'No roles found'
        ELSE 'Roles found'
    END AS role_status
FROM 
    movie_details AS md
WHERE 
    md.role_rank <= 5
ORDER BY 
    md.production_year DESC, total_roles DESC
LIMIT 10;
