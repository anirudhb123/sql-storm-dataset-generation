WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        CASE 
            WHEN m.title IS NULL THEN 'Unknown Title' 
            ELSE m.title 
        END AS title,
        m.production_year,
        COALESCE(cn.name, 'No Company') AS company_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS company_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(cn.name, 'No Company') AS company_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year) AS company_rank
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        m.production_year < (SELECT MAX(production_year) FROM aka_title)
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.company_name,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    MAX(CASE WHEN ri.role IS NOT NULL THEN 1 ELSE 0 END) AS has_roles,
    STRING_AGG(DISTINCT wi.info, ', ') FILTER (WHERE wi.info IS NOT NULL) AS keywords,
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_cast
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    role_type ri ON ci.role_id = ri.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword wi ON mk.keyword_id = wi.id
WHERE 
    mh.company_rank = 1
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.company_name
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 OR 
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    mh.production_year DESC,
    total_cast DESC;

This SQL query leverages several advanced SQL concepts, including recursion with `WITH RECURSIVE`, outer joins, conditional aggregation via `CASE` statements, the `STRING_AGG` function, and filtering based on computed conditions. It aims to analyze a hierarchy of movies alongside cast information and associated keywords while ensuring distinct counts and orderly presentation of results based on the total cast and production year.
