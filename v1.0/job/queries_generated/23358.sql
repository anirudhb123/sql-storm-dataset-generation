WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ct.kind, 'Unknown') AS company_type,
        1 AS level
    FROM 
        aka_title m 
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        m.production_year IS NOT NULL 
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(ct.kind, 'Unknown') AS company_type,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.id = mh.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    mh.title,
    mh.production_year,
    mh.company_type,
    COUNT(DISTINCT c.person_id) AS actor_count,
    SUM(CASE WHEN info.info LIKE '%award%' THEN 1 ELSE 0 END) AS awards_related_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_info info ON mh.movie_id = info.movie_id
WHERE 
    mh.level <= 3 
    AND (mh.company_type IS NOT NULL OR mh.company_type <> 'Unknown')
GROUP BY 
    mh.title, mh.production_year, mh.company_type
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    awards_related_info DESC, 
    mh.production_year ASC, 
    mh.title
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

This query accomplishes the following:

1. It creates a recursive common table expression (CTE) to generate a hierarchy of movies and their respective companies.
2. It pulls metadata from various joins, including company types and complete cast information.
3. It counts the distinct actors associated with each movie and sums up the information pertaining to awards.
4. It applies various filters, groupings, and ordering which include obscure NULL checks and non-NULL behaviors.
5. It implements pagination logic with OFFSET and FETCH to retrieve a specific subset of the results. 

This combination of constructs makes it a complex yet sophisticated SQL example that showcases multiple SQL features and semantics.
