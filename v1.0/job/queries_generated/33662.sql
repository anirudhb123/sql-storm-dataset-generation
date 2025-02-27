WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(c.name, 'Unknown Company') AS company_name,
        1 AS level
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year BETWEEN 1990 AND 2020
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(c.name, 'Unknown Company') AS company_name,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        mh.level < 3
),
AggregatedMovies AS (
    SELECT 
        title,
        production_year,
        COUNT(DISTINCT company_name) AS company_count,
        SUM(CASE 
            WHEN level = 1 THEN 1 
            ELSE 0 
        END) AS direct_companies_count
    FROM 
        MovieHierarchy
    GROUP BY 
        title, production_year
)
SELECT 
    am.title,
    am.production_year,
    am.company_count,
    am.direct_companies_count,
    ROW_NUMBER() OVER (ORDER BY am.production_year DESC, am.company_count DESC) AS rank,
    STRING_AGG(DISTINCT am.company_name, ', ') FILTER (WHERE am.company_name IS NOT NULL) AS company_names
FROM 
    AggregatedMovies am
LEFT JOIN 
    movie_info mi ON am.production_year = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    it.info IS NOT NULL
GROUP BY 
    am.title, am.production_year, am.company_count, am.direct_companies_count
HAVING 
    COUNT(DISTINCT am.company_name) > 1
ORDER BY 
    am.production_year DESC,
    am.company_count DESC;
