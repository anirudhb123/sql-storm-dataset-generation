WITH RECURSIVE MovieHierarchy AS (
    SELECT
        parent.movie_id AS parent_id,
        child.movie_id AS child_id,
        1 AS level
    FROM
        movie_link AS parent
    JOIN
        movie_link AS child ON parent.linked_movie_id = child.movie_id
    WHERE
        parent.link_type_id = 1 -- Assuming link_type_id = 1 indicates a certain relationship
    
    UNION ALL
    
    SELECT
        mh.parent_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM
        MovieHierarchy AS mh
    JOIN
        movie_link AS ml ON mh.child_id = ml.movie_id
    WHERE
        ml.link_type_id = 1
)
SELECT
    t.title AS Movie_Title,
    ak.name AS Actor_Name,
    ku.keyword AS Keyword,
    COUNT(DISTINCT cc.person_id) AS Total_Actors,
    COUNT(DISTINCT mh.child_id) AS Related_Movies,
    AVG(mi.production_year) AS Average_Production_Year,
    STRING_AGG(DISTINCT inform.info ORDER BY inform.info) AS Additional_Info
FROM
    title AS t
JOIN
    movie_info AS mi ON t.id = mi.movie_id
LEFT JOIN
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN
    keyword AS ku ON mk.keyword_id = ku.id
LEFT JOIN
    complete_cast AS cc ON t.id = cc.movie_id
LEFT JOIN
    aka_name AS ak ON cc.subject_id = ak.person_id
LEFT JOIN
    (SELECT
        pi.person_id,
        pi.info
     FROM
        person_info AS pi
     WHERE
        pi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('bio', 'trivia')))
    AS inform ON inform.person_id = cc.person_id
LEFT JOIN
    MovieHierarchy AS mh ON mh.parent_id = t.id
GROUP BY
    t.title, ak.name, ku.keyword
HAVING
    COUNT(DISTINCT cc.person_id) > 0 
    AND AVG(mi.production_year) > 2000
ORDER BY
    t.title,
    Total_Actors DESC;

This query explores a recursive CTE to create a hierarchy of movies based on links between them. It aggregates related information about movies, actors, and keywords while applying different JOIN types.
