WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        (SELECT title FROM aka_title WHERE id = ml.linked_movie_id) AS title,
        (SELECT production_year FROM aka_title WHERE id = ml.linked_movie_id) AS production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name,
    mt.title,
    mt.production_year,
    rt.role,
    COUNT(DISTINCT c.id) AS total_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN mi.info_type_id = 1 THEN mi.info::numeric END) AS average_rating,
    SUM(mi.info_type_id = 2) AS review_count
FROM 
    movie_hierarchy mh
JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
JOIN 
    cast_info c ON mh.movie_id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    role_type rt ON c.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
    AND (mh.production_year IS NULL OR mh.production_year > 2010)
GROUP BY 
    ak.name, mt.title, mt.production_year, rt.role
HAVING 
    COUNT(DISTINCT c.id) > 10
ORDER BY 
    average_rating DESC NULLS LAST, 
    total_cast DESC, 
    mt.production_year ASC;

### Explanation:
- **CTE Usage**: A recursive Common Table Expression (CTE) `movie_hierarchy` is used to build a hierarchy of movies starting from those produced after 2000 and linking them to their sequels or related movies.
- **Joins**: Various types of joins are used; `INNER JOIN` for mandatory connections like movie-company and cast, and `LEFT JOIN` for optional data like keywords and additional movie information.
- **Aggregations**: The query counts distinct cast members and averages numeric ratings based on a specific info type, showing advanced aggregate functions.
- **String Aggregation**: `STRING_AGG` is applied to concatenate keywords associated with each movie.
- **NULL Logic**: Predicates check for NULL conditions while ensuring no unwanted data silos.
- **HAVING Clause**: Ensures that only movies with a substantial cast size are included in the results.
- **Order By**: Results are ordered by average ratings gracefully handling NULL values and ensures that the highest rated movies appear first.
