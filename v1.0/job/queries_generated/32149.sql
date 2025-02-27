WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(STRING_AGG(DISTINCT concat(aka.name, ' [', cct.kind, ']'), ', '), 'No Cast') AS cast_members,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(p.age) FILTER (WHERE p.age IS NOT NULL) AS average_age,
    MAX(m.production_year) OVER () AS latest_movie_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT person_id, 
            EXTRACT(YEAR FROM AGE(NOW(), date_of_birth)) AS age 
     FROM person_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Date of Birth')
    ) p ON ci.person_id = p.person_id
LEFT JOIN 
    comp_cast_type cct ON ci.role_id = cct.id
WHERE 
    mh.level = 1
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, keyword_count DESC
LIMIT 10;

### Explanation:
- This query utilizes a recursive Common Table Expression (CTE) `MovieHierarchy` to fetch movies released after the year 2000 and any linked movies up to a depth of 3 levels.
- It then joins this hierarchy with various tables to gather cast member information, associated keywords, and the average age of persons based on their date of birth.
- The `STRING_AGG` function is used to aggregate the names of cast members along with their roles.
- Conditional aggregation using a `FILTER` clause computes the average age only for cast members whose ages are available.
- The results are grouped by movie ID, title, and production year, ordered by the production year and keyword count for relevance.
