WITH RECURSIVE MovieHopper AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level,
        NULL::INTEGER AS parent_movie_id
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA'
        AND t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        lm.id,
        lt.title,
        lm.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        MovieHopper mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    JOIN 
        title lm ON lt.id = lm.id
    WHERE 
        mh.level < 3 
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    CASE 
        WHEN mh.level = 1 THEN 'Original'
        WHEN mh.level = 2 THEN 'Sequel'
        ELSE 'Spinoff' 
    END AS Relation_Type,
    COALESCE(
        (SELECT STRING_AGG(DISTINCT k.keyword, ', ')
         FROM movie_keyword mk
         JOIN keyword k ON mk.keyword_id = k.id
         WHERE mk.movie_id = mh.movie_id), 'No keywords') AS Keywords,
    (SELECT COUNT(DISTINCT ci.person_id)
     FROM cast_info ci
     WHERE ci.movie_id = mh.movie_id) AS Cast_Count,
    COUNT(DISTINCT c2.id) AS Company_Count,
    SUM(CASE 
            WHEN pt.info_type_id IS NOT NULL THEN 1 ELSE 0 
        END) AS Info_Provided
FROM 
    MovieHopper mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name c2 ON mc.company_id = c2.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info pt ON mh.movie_id = pt.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.id) > 5
ORDER BY 
    mh.production_year DESC, Cast_Count DESC;

