WITH RECURSIVE MovieHierarchy AS (
    -- Create a CTE to build a hierarchy of movies linked to one another
    SELECT 
        ml.movie_id AS root_movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel') -- Assume 'sequel' is the link type

    UNION ALL

    SELECT 
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT 
    m.title AS Movie_Title,
    COALESCE(a.name, 'Unknown') AS Actor_Name,
    COUNT(DISTINCT mh.linked_movie_id) AS Linked_Movies_Count,
    SUM(mi.info IS NOT NULL) AS Info_Count,  -- Counting non-null info
    AVG(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS Avg_Nr_Order,  -- Handle NULLs in nr_order
    STRING_AGG(DISTINCT kw.keyword, ', ') AS Keywords,  -- Concatenate unique keywords
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No Note' END) AS Last_Note
FROM 
    aka_title m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.root_movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id 
-- Select movies released in the last decade
WHERE 
    m.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
GROUP BY 
    m.title, a.name
ORDER BY 
    Linked_Movies_Count DESC, Avg_Nr_Order ASC
LIMIT 50;

-- Subquery to find titles which are part of a series
WITH SeriesTitles AS (
    SELECT 
        t.title, 
        t.production_year,
        pt.info
    FROM 
        title t
    JOIN 
        person_info pt ON t.imdb_id = pt.person_id
    WHERE 
        pt.info_type_id = (SELECT id FROM info_type WHERE info = 'active_series')
      AND 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'series')
)

SELECT 
    st.title,
    st.production_year,
    COUNT(*) AS Member_Cast_Count
FROM 
    SeriesTitles st
JOIN 
    complete_cast cc ON st.imdb_id = cc.movie_id 
GROUP BY
    st.title, st.production_year
HAVING 
    COUNT(*) > 5
ORDER BY 
    st.production_year DESC;

-- Additional Count of movies which do not have any entry in movie_info
SELECT 
    m.title,
    COUNT(mi.id) AS Info_Entry_Count,
    CASE 
        WHEN COUNT(mi.id) = 0 THEN 'No Info Available' 
        ELSE 'Info Available' 
    END AS Info_Status
FROM 
    aka_title m
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
GROUP BY 
    m.title
ORDER BY 
    Info_Entry_Count ASC;

-- Use of a CROSS JOIN to find actors who have worked in each possible movie with no intersection
SELECT 
    a.name AS Actor_Name,
    COUNT(DISTINCT m.id) AS Movies_Not_Acted_In
FROM 
    aka_name a
CROSS JOIN 
    aka_title m
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id AND m.id = ci.movie_id
WHERE 
    ci.id IS NULL
GROUP BY 
    a.name
ORDER BY 
    Movies_Not_Acted_In DESC;
