WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all titles and their immediate info
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL

    -- Recursive case: Find linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    dh.person_id,
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
    COALESCE(SUM(mv.info IS NOT NULL AND mv.info_type_id = 1), 0) AS rating_info,
    AVG(CASE WHEN ci.note IS NULL OR ci.note = '' THEN NULL ELSE ci.nr_order END) OVER (PARTITION BY dh.person_id) AS avg_order
FROM 
    complete_cast cc
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    movie_info mv ON mc.movie_id = mv.movie_id
JOIN 
    MovieHierarchy m ON cc.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id AND ci.person_id = ak.person_id
JOIN 
    person_info dh ON ak.person_id = dh.person_id
WHERE 
    mv.info IS NOT NULL    
    AND m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    dh.person_id, ak.name, m.title, m.production_year
ORDER BY 
    avg_order DESC, keyword_count DESC, rating_info DESC;

This SQL query uses a recursive Common Table Expression (CTE) to retrieve movie titles produced from 2000 onwards, alongside their linked movies through a `movie_link` table structure. It also aggregates various pieces of information such as actor names, keyword counts, and average order of appearance in movie casts.

The select statement combines data from multiple tables, including `akas_name`, `movie_companies`, and `complete_cast`, while applying filtering and aggregation. The `COALESCE` function and various CASE statements handle NULL logic, ensuring comprehensive results. The final result set is ordered by average order and keyword count to reflect priority based on the significance of the roles and movie information available.
