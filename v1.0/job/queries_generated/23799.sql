WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
  
    UNION ALL
  
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1 AS level
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.linked_movie_id
)
SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title,
    t.production_year,
    COALESCE(c.name, 'Unknown Company') AS company_name,
    COUNT(DISTINCT ci.id) AS num_cast_members,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn,
    COUNT(CASE WHEN p.gender = 'F' THEN 1 END) AS female_cast_count,
    MAX(CASE WHEN f.industry IS NOT NULL THEN f.industry ELSE 'Unknown Industry' END) AS film_industry
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON ci.person_id = p.person_id AND (p.info_type_id = (SELECT id FROM info_type WHERE info = 'Gender') OR p.info_type_id IS NULL)
LEFT JOIN 
    (SELECT DISTINCT company_id, 'Film' AS industry FROM company_name WHERE country_code = 'US' UNION ALL 
     SELECT DISTINCT company_id, 'TV' AS industry FROM company_name WHERE country_code = 'UK') f ON c.id = f.company_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
GROUP BY 
    a.id, a.name, t.title, t.production_year, c.name
HAVING 
    COUNT(DISTINCT ci.id) > 2
ORDER BY 
    a.name, t.production_year DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
