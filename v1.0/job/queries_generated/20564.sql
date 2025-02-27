WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (
            SELECT id FROM kind_type WHERE kind = 'movie'
        )
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year IS NOT NULL
)
SELECT 
    p.name AS person_name,
    ARRAY_AGG(DISTINCT kh.keyword) AS keywords,
    COALESCE(AVG(mi.info::numeric), 0) AS average_rating,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    MIN(mh.production_year) AS first_movie_year,
    MAX(mh.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS featured_movies,
    COUNT(DISTINCT CASE WHEN c.role_id IS NULL THEN c.note END) AS unnamed_roles
FROM 
    aka_name p
LEFT JOIN 
    cast_info c ON p.person_id = c.person_id
LEFT JOIN 
    movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
LEFT JOIN 
    keyword kh ON kh.id = mk.keyword_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    p.name IS NOT NULL
    AND p.name NOT LIKE '%[ ]%'
    AND (mh.level = 1 OR (mh.level > 1 AND mh.production_year < 2000))
GROUP BY 
    p.id
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    average_rating DESC NULLS LAST
LIMIT 50;

### Explanation:
1. **CTE (Common Table Expression)**: The `movie_hierarchy` CTE recursively retrieves movie links, allowing exploration of related movies starting from entries in the `aka_title` table. It captures hierarchy levels of linked movies.

2. **SELECT Statement**: The main query selects multiple relevant fields, including person names, aggregated keywords, average ratings, and counts of movies in the hierarchy.

3. **Joins**: The query uses outer joins to handle missing data gracefully, ensuring that even if some records do not have corresponding entries in other tables (like `movie_info` or `movie_keyword`), results will still include those actors.

4. **Aggregations**:
   - `ARRAY_AGG`: Collects a distinct list of keywords associated with each person.
   - `AVG` and `COUNT`: These functions provide average ratings and count movies for those actors.

5. **Filters**: The `WHERE` clause includes complex predicates to filter data based on null values, name patterns, and levels in the movie hierarchy.

6. **HAVING Clause**: Ensures that only people with more than two movies linked in recent years are included.

7. **ORDER BY and LIMIT**: Results are ordered by average ratings with NULL ratings last, limiting output to 50 records, which provides an easy way of ranking performers.

8. **NULL Handling & Corner Cases**: The query sensibly manages NULL values from various joins, using `COALESCE` to replace NULL averages with zero, and in the grouping, it verifies that names are not empty spaces.

Overall, this SQL query showcases advanced SQL techniques while reflecting a complex real-world scenario in the movie industry.
