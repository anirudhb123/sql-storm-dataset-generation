WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title AS movie_title, mt.production_year, NULL::integer AS parent_id
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT m.id, m.title, m.production_year, mh.movie_id
    FROM aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    Array_agg(DISTINCT kw.keyword) AS keywords,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_nr_order,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT CTE.starred_by) AS total_stars
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN (
    SELECT DISTINCT ci.movie_id AS starred_by
    FROM cast_info ci
    JOIN aka_name ak ON ak.person_id = ci.person_id
    WHERE ak.name LIKE '%John%'
) AS CTE ON CTE.starred_by = m.movie_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.movie_id, m.movie_title, m.production_year, ak.name
ORDER BY 
    m.production_year DESC, COUNT(DISTINCT CTE.starred_by) DESC;
