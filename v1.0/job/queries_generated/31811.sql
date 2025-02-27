WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(COALESCE(CAST(SUBSTRING(pi.info FROM 'Age: (\d+)$') AS INTEGER), 0)) AS avg_age,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(CASE WHEN c.note IS NOT NULL THEN c.note ELSE 'No Note' END) AS latest_note,
    MIN(CASE WHEN c.note IS NOT NULL THEN c.note ELSE 'No Note' END) AS oldest_note
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id 
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Age')
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    actor_count DESC, mh.production_year DESC;

This SQL query recursively builds a hierarchy of movies released between 2000 and 2020, gathers various statistics on the actors involved, and retrieves keyword information while ensuring handling of potentially NULL values and using aggregate functions to summarize the data.
