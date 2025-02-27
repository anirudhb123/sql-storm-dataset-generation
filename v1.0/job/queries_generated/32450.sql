WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY[t.id] AS path
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.path || m.linked_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link m ON mh.movie_id = m.movie_id
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
)

SELECT 
    ak.name AS actor_name,
    k.keyword AS movie_keyword,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT cc.id) AS total_cast,
    AVG(DISTINCT CASE 
        WHEN cc.nr_order IS NOT NULL THEN cc.nr_order 
        ELSE NULL 
    END) AS avg_cast_order,
    STRING_AGG(DISTINCT pc.name, ', ') AS production_companies,
    MIN(CASE WHEN ti.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN mi.info END) AS min_budget
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title t ON mh.movie_id = t.id
LEFT OUTER JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT OUTER JOIN 
    company_name pc ON mc.company_id = pc.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_info_idx ti ON mi.movie_id = ti.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, k.keyword, t.title, t.production_year
HAVING 
    COUNT(DISTINCT cc.id) > 1
ORDER BY 
    total_cast DESC, t.production_year DESC;


This SQL query leverages various elements of SQL such as recursive CTEs to build a hierarchy of movies, aggregates for counting and averaging cast roles, string aggregation for concatenating production company names, and uses a variety of joins (including outer joins) for integrating data across multiple tables. Additionally, the query incorporates conditions on NULL values, which makes it robust for diverse datasets.
