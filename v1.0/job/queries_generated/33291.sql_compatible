
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM title m
    WHERE m.kind_id = (
        SELECT id FROM kind_type WHERE kind = 'movie'
    )
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
aggregated_cast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(n.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name n ON ci.person_id = n.person_id
    GROUP BY ci.movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, co.name, ct.kind
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ac.total_cast, 0) AS total_cast,
    ac.cast_names,
    COALESCE(mc_info.company_count, 0) AS total_companies,
    STRING_AGG(DISTINCT mc_info.company_name || ' (' || mc_info.company_type || ')', '; ') AS company_details
FROM movie_hierarchy mh
LEFT JOIN aggregated_cast ac ON mh.movie_id = ac.movie_id
LEFT JOIN movie_company_info mc_info ON mh.movie_id = mc_info.movie_id
GROUP BY mh.movie_id, mh.title, mh.production_year, ac.total_cast, ac.cast_names, mc_info.company_count
ORDER BY mh.production_year DESC, total_cast DESC;
