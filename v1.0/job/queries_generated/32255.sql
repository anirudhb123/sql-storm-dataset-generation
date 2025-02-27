WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_link ml ON ml.linked_movie_id = mt.id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    AVG(mo.info->>'rating') AS average_rating,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COALESCE(cn.name, 'Unknown Company') AS production_company
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_info mo ON mo.movie_id = mh.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, cn.name
HAVING 
    ARRAY_LENGTH(ARRAY_AGG(DISTINCT mk.keyword), 1) > 2
ORDER BY 
    average_rating DESC, mh.production_year DESC, mh.level ASC;

Explanation:
- The query begins with a Common Table Expression (CTE) that recursively identifies movies and their links using the `movie_link` table, forming a hierarchy.
- Then it selects relevant details from the `MovieHierarchy`, including the total number of unique cast members, their names, average ratings, keyword counts, and production companies associated with each movie.
- A series of left joins are used to gather information from related tables such as `complete_cast`, `cast_info`, `aka_name`, `movie_info`, `movie_companies`, and `company_name`.
- The results are grouped by movie details and production company, filtering those that have more than two distinct keywords.
- Finally, the results are ordered by average rating and production year.
