WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        COALESCE(p.name, 'Unknown') AS director_name,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name p ON mc.company_id = p.imdb_id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cn.name, 'Unknown') AS director_name,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title ct ON ml.linked_movie_id = ct.id
    LEFT JOIN 
        movie_companies mc ON ct.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.imdb_id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    WHERE 
        mh.level < 3
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.director_name,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    SUM(CASE WHEN mw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    AVG(COALESCE(mk.person_role_id, 0)) AS avg_role_id
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
LEFT JOIN 
    role_type mk ON ci.person_role_id = mk.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.director_name
HAVING 
    COUNT(DISTINCT ci.person_id) > 1   -- Only consider movies with more than one cast member
ORDER BY 
    mh.production_year DESC,
    CAST(mh.movie_id AS TEXT)
LIMIT 100;
This SQL query includes the following constructs:

1. **Recursive CTE**: To build a hierarchy of movies linked by directorial relationships.
2. **Outer Joins**: To include all relevant data from different tables while allowing for possible NULL values.
3. **Aggregate Functions**: To count the number of cast members and to sum keyword occurrences for each movie.
4. **String Aggregation**: To combine actor names into a single string for each movie.
5. **Complex Predicates**: In the `HAVING` clause to filter out movies with fewer than two cast members.

This query aims to provide a performance benchmark while fetching a wealth of information regarding movies and their relationships to directors, casts, and keywords.
