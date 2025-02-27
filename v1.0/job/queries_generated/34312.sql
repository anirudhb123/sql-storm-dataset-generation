WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.produc_tion_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    ARRAY_AGG(DISTINCT c.name) AS Cast_Names,
    AVG(pi.some_numeric_field) AS Avg_Info_Type_Value,
    COUNT(DISTINCT kw.keyword) AS Keyword_Count,
    COUNT(mc.id) FILTER (WHERE ct.kind = 'Production') AS Production_Company_Count,
    COALESCE(NULLIF(SUM(mi.some_metric_field), 0), -1) AS Total_Metric_Aggregate,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year) AS Year_Rank
FROM
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON cc.movie_id = m.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ca ON ca.person_id = ci.person_id
LEFT JOIN 
    person_info pi ON pi.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id
WHERE 
    m.level < 3
GROUP BY 
    m.movie_id, m.title, m.production_year
ORDER BY 
    m.production_year DESC;
