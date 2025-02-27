WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieCTE mc ON ml.movie_id = mc.movie_id
    WHERE 
        depth < 3 -- limit to 3 levels of linked movies
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords_list
FROM 
    MovieCTE mt
LEFT JOIN 
    cast_info cc ON mt.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL -- Ensure that we have actor names
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    total_cast > 1 AND total_keywords > 0
ORDER BY 
    mt.production_year DESC, total_cast DESC
LIMIT 10;

-- Additional insights can further be gathered by including the information about companies involved
SELECT 
    mt.title AS movie_title,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    aka_title mt
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mt.title
HAVING 
    company_count > 1
ORDER BY 
    company_count DESC
LIMIT 5;
