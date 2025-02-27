WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_of_id,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_of_id,
        mh.hierarchy_level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON mt.id = ml.linked_movie_id
    WHERE 
        mh.hierarchy_level < 5  -- Limit to 5 levels deep
)

SELECT 
    ak.person_id,
    ak.name AS actor_name,
    title.title,
    title.production_year,
    COALESCE(c.name_pcode_nf, 'UNKNOWN') AS company_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    SUM(CASE WHEN title.production_year < 2005 THEN 1 ELSE 0 END) AS pre_2005_titles,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY title.production_year DESC) AS row_num
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    MovieHierarchy title ON title.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name_pcode_nf IS DISTINCT FROM ak.surname_pcode 
    AND (c.country_code IS NOT NULL OR c.country_code IS NULL)  -- Bizarre NULL logic
GROUP BY 
    ak.person_id, ak.name, title.title, title.production_year, c.name_pcode_nf
HAVING 
    COUNT(DISTINCT ci.movie_id) > 2  -- More than two movies for the actor
ORDER BY 
    movie_count DESC,
    pre_2005_titles DESC,
    actor_name;
