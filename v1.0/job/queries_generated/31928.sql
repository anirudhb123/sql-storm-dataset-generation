WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        0 AS hierarchy_level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000   -- Select movies released in or after 2000

    UNION ALL

    SELECT 
        linked.movie_id, 
        l.title, 
        mh.hierarchy_level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title l ON ml.linked_movie_id = l.id 
    WHERE 
        mh.hierarchy_level < 3  -- Limit to 3 levels of depth
)

SELECT 
    ak.name AS Actor_Name,
    at.title AS Movie_Title,
    rt.role AS Role,
    STRING_AGG(DISTINCT k.keyword, ', ') AS Keywords,
    COUNT(DISTINCT m.id) OVER (PARTITION BY ak.id) AS Total_Movies_Acted,
    COALESCE(ci.note, 'No Note') AS Cast_Note,
    mv.production_year,
    mh.hierarchy_level
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
JOIN 
    title mv ON mv.id = at.id
WHERE 
    ak.name IS NOT NULL
    AND mv.production_year IS NOT NULL
    AND (mv.production_year > 2010 OR ak.name ILIKE 'A%')  -- Filter for specific criteria
GROUP BY 
    ak.id, at.id, rt.role, ci.note, mv.production_year, mh.hierarchy_level
ORDER BY 
    Total_Movies_Acted DESC, Actor_Name, Movie_Title;
