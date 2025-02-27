WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_companies c ON t.id = c.movie_id
    LEFT JOIN 
        company_type ct ON c.company_type_id = ct.id
    WHERE 
        ct.kind = 'Distributor'
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id 
    WHERE 
        mh.depth < 5
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT cwr.actor_name) AS actor_count,
        SUM(CASE WHEN cwr.role_name = 'Lead' THEN 1 ELSE 0 END) AS lead_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_with_roles cwr ON mh.movie_id = cwr.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS total_actors,
    COALESCE(md.lead_count, 0) AS total_leads,
    CASE
        WHEN md.lead_count > 0 THEN 'Has Leads'
        ELSE 'No Leads'
    END AS lead_status
FROM 
    movie_details md
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
WHERE 
    md.production_year BETWEEN 2000 AND 2025
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
