WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000 AND 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Series%')
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    WHERE 
        mh.level < 5
),
role_summary AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS total_roles,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS total_notes
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
name_summary AS (
    SELECT 
        ak.person_id,
        STRING_AGG(ak.name, ', ') AS all_names,
        COUNT(DISTINCT ak.id) AS name_count
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(rs.total_roles, 0) AS role_count,
    COALESCE(rs.total_notes, 0) AS note_count,
    ns.all_names,
    ns.name_count,
    COUNT(DISTINCT mc.company_id) AS total_companies
FROM 
    movie_hierarchy mh
LEFT JOIN 
    role_summary rs ON mh.movie_id = rs.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    name_summary ns ON cc.subject_id = ns.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ns.all_names, ns.name_count, rs.total_roles, rs.total_notes
ORDER BY 
    mh.production_year DESC,
    role_count DESC,
    note_count DESC;
