WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title linked ON ml.linked_movie_id = linked.id
    JOIN 
        MovieHierarchy mh ON linked.id = mh.movie_id
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Release_Year,
    COALESCE(ca.name, 'Unknown') AS Cast_Name,
    COUNT(DISTINCT mc.company_id) AS Company_Count,
    ARRAY_AGG(DISTINCT k.keyword) AS Keywords,
    SUM(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE 0 END) AS Total_Info_Length,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ca.id) DESC) AS Rank_By_Cast_Size
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ca ON ca.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    mi.info IS NOT NULL 
    AND mi.info_type_id IN (1, 2)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ca.name
ORDER BY 
    mh.production_year DESC, COUNT(DISTINCT ca.id) DESC;
This SQL query performs the following actions:

1. It defines a recursive Common Table Expression (CTE) called `MovieHierarchy` to find movies produced between 2000 and 2023 and establishes a hierarchy of linked movies through the `movie_link` table.

2. It selects movie titles, release years, cast names, and counts the number of associated production companies.

3. It aggregates keywords related to each movie into an array.

4. It calculates the total length of info text for specific info types while considering only non-null values.

5. It uses a window function to rank movies based on the size of their cast per production year.

6. Finally, results are grouped and ordered to show the most recent movies with the largest casts at the top.
