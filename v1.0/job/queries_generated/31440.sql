WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        m.imdb_index, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        m.imdb_index, 
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT p.id) AS actor_count,
        STRING_AGG(DISTINCT p.name, ', ') AS actors
    FROM
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id
),

keyword_summary AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.imdb_index,
    COALESCE(cs.actor_count, 0) AS actor_count,
    COALESCE(cs.actors, 'No actors') AS actors,
    COALESCE(ks.keywords, 'No keywords') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
WHERE 
    mh.level = 1
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC
LIMIT 100;

-- Performance benchmarking
EXPLAIN ANALYZE
WITH RECURSIVE movie_hierarchy AS (
    ...
)
SELECT 
    ...

This SQL query performs the following:

1. **Recursive CTE (`movie_hierarchy`)**: It gathers information about movies released from the year 2000 onwards and their hierarchy based on linked movies.
  
2. **Cast Summary CTE (`cast_summary`)**: It calculates the number of distinct actors in each movie and concatenates their names into a string.

3. **Keyword Summary CTE (`keyword_summary`)**: It aggregates keywords associated with each movie into a concatenated string.

4. **Main Query**: The main query selects movie information along with actor counts and keyword summaries. Uses `LEFT JOIN` to include movies that may not have associated data in the cast and keywords: gracefully handling NULL values with `COALESCE`.

5. **Performance Benchmarking**: The use of `EXPLAIN ANALYZE` at the end of the query structure helps to benchmark and analyze the performance of the constructed SQL statement.

This complex query structure utilizes multiple advanced SQL features, making it suitable for performance benchmarking tasks.
