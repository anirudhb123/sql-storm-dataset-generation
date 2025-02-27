WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS TEXT) AS path
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Assuming '1' refers to a specific movie type

    UNION ALL

    SELECT 
        linked.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' > ' || m.title AS TEXT)
    FROM 
        movie_link linked
    JOIN 
        aka_title m ON linked.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON linked.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT cc.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS num_plot_descriptions,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS actor_rank
FROM 
    cast_info cc
JOIN 
    aka_name a ON cc.person_id = a.person_id
JOIN 
    aka_title m ON cc.movie_id = m.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = 1 -- Assuming '1' is for plot information
WHERE 
    m.production_year >= 2000
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT cc.person_id) > 5
ORDER BY 
    m.production_year DESC, actor_rank
LIMIT 10;

-- Performance Benchmarking Query
WITH info_counts AS (
    SELECT 
        movie_id,
        COUNT(*) AS total_info
    FROM 
        movie_info
    GROUP BY 
        movie_id
),
unique_keywords AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS num_unique_keywords
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    COALESCE(ic.total_info, 0) AS total_info_count,
    COALESCE(uk.num_unique_keywords, 0) AS unique_keyword_count,
    CASE 
        WHEN ic.total_info IS NULL AND uk.num_unique_keywords IS NULL THEN 'No data'
        WHEN ic.total_info > 0 THEN 'Has info'
        ELSE 'No info'
    END AS info_status
FROM 
    aka_title m
LEFT JOIN 
    info_counts ic ON m.id = ic.movie_id
LEFT JOIN 
    unique_keywords uk ON m.id = uk.movie_id
WHERE 
    m.production_year >= 2010
ORDER BY 
    total_info_count DESC
LIMIT 5;

-- Final Query combining SUBQUERIES for Complex Data Analysis
SELECT 
    m.title,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    SUM(CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END) AS corporate_producers,
    AVG(p.personal_info) AS avg_person_info, -- Assuming this aggregate for male actors
    MAX(m.creation_year) AS latest_release
FROM 
    movie_info mi
JOIN 
    movie_companies mc ON mi.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info cc ON mi.movie_id = cc.movie_id
JOIN (
    SELECT 
        person_id,
        COUNT(*) AS personal_info
    FROM 
        person_info
    WHERE 
        info_type_id = 2 -- Assuming type '2' indicates a specific set of info
    GROUP BY 
        person_id
) p ON cc.person_id = p.person_id
JOIN 
    aka_title m ON mi.movie_id = m.id
WHERE 
    mi.info_type_id = 1
GROUP BY 
    m.title
ORDER BY 
    total_cast DESC
LIMIT 10;
