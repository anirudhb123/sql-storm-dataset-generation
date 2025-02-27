WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m.production_year >= 2000
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN r.role = 'Director' THEN ci.person_id END) AS total_directors,
        COUNT(DISTINCT CASE WHEN r.role = 'Actor' THEN ci.person_id END) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),

movie_overview AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        cs.total_cast,
        cs.total_directors,
        cs.total_actors,
        ROW_NUMBER() OVER (PARTITION BY h.production_year ORDER BY h.production_year DESC) AS rn
    FROM 
        movie_hierarchy h
    LEFT JOIN 
        cast_summary cs ON h.movie_id = cs.movie_id
)

SELECT 
    mo.title,
    mo.production_year,
    mo.total_cast,
    mo.total_directors,
    mo.total_actors,
    COALESCE(cn.name, 'Unknown') AS company_name,
    STRING_AGG(DISTINCT ko.keyword, ', ') AS keywords
FROM 
    movie_overview mo
LEFT JOIN 
    movie_companies mc ON mo.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mo.movie_id = mk.movie_id
LEFT JOIN 
    keyword ko ON mk.keyword_id = ko.id
WHERE 
    mo.total_cast > 5 OR mo.total_directors > 1
GROUP BY 
    mo.movie_id, mo.title, mo.production_year, mo.total_cast, mo.total_directors, mo.total_actors, cn.name
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0
ORDER BY 
    mo.production_year DESC, mo.total_cast DESC;
