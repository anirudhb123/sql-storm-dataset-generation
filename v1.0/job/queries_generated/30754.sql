WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') 
        AND mi.info LIKE '%Drama%'
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE 
        ml.linked_movie_id = mh.movie_id
)

SELECT 
    m.title,
    m.production_year,
    ci.kind AS cast_type,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    AVG(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN CAST(pi.info AS DECIMAL) ELSE NULL END) AS avg_rating,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
GROUP BY 
    m.movie_id, m.title, m.production_year, ci.kind
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    avg_rating DESC NULLS LAST;

This SQL query performs a few complex operations that can be utilized for performance benchmarking while exploring the relationships in the movie database schema provided:

1. **CTE Usage**: It uses a recursive common table expression (`movie_hierarchy`) to build a hierarchy of movies linked together by the movie links. 

2. **Joins**: Combines data from several tables using both inner and outer joins, retrieving additional details about the cast and associated names.

3. **Aggregations and Window Functions**: It counts the distinct number of cast members for each movie and computes the average rating dynamically with a conditional aggregation.

4. **String Aggregation**: It collects alternate names of people involved in the movies using `STRING_AGG`.

5. **HAVING Clause**: Filters the results to include only those movies with more than 5 unique cast members.

6. **NULL Logic**: The average rating calculation accommodates potential NULL values, ensuring that they are handled correctly using conditional aggregates.

The final ordering of results sorts by the average ratings, placing movies without ratings at the end.
