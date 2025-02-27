WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    CONCAT(p.firstname, ' ', p.lastname) AS actor_full_name,
    m.id AS movie_id,
    m.title,
    COALESCE(ROUND(AVG(CASE WHEN r.role = 'lead' THEN c.nr_order ELSE NULL END) OVER (PARTITION BY m.id), 2), 0) AS avg_lead_order,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    SUM(CASE 
            WHEN cm.kind = 'Production' AND cn.country_code = 'USA' THEN 1 
            ELSE 0 
        END) AS usa_production_count,
    STRING_AGG(DISTINCT CAST(p.gender AS text), ', ') AS gender_distribution,
    m.production_year,
    CASE
        WHEN EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = m.id 
              AND mi.info_type_id = (SELECT it.id FROM info_type it WHERE it.info = 'box office' LIMIT 1)
              AND mi.info IS NOT NULL
        ) THEN 'Box office info available'
        ELSE 'No box office info'
    END AS box_office_status
FROM 
    movie_companies mc
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    aka_title m ON mc.movie_id = m.id
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name p ON c.person_id = p.person_id
LEFT JOIN 
    movie_keyword k ON m.id = k.movie_id
LEFT JOIN 
    comp_cast_type cc ON c.person_role_id = cc.id
LEFT JOIN 
    complete_cast cc2 ON m.id = cc2.movie_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    m.production_year < 2000 
    AND (m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')) 
    AND (p.name IS NOT NULL OR p.name IS NOT NULL) 
GROUP BY 
    m.id, p.firstname, p.lastname
ORDER BY 
    avg_lead_order DESC NULLS LAST, 
    total_keywords DESC;
