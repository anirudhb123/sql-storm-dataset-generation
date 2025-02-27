WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assume 1 corresponds to 'Movie'
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    rc.name AS lead_actor,
    mk.keywords,
    COUNT(DISTINCT ci.id) AS total_cast,
    COALESCE(AVG(CASE WHEN ci.note IS NOT NULL THEN LENGTH(ci.note) ELSE 0 END), 0) AS avg_note_length,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN 'Has Keywords' 
        ELSE 'No Keywords' 
    END AS keyword_status
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_cast rc ON mh.movie_id = rc.movie_id AND rc.actor_rank = 1
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, rc.name, mk.keywords
ORDER BY 
    mh.production_year DESC, mh.title;

This SQL query performs performance benchmarking with various constructs such as:

1. **Recursive CTE (`movie_hierarchy`)**: It builds a hierarchy of movies via linked movies.
2. **Window Function (`ROW_NUMBER()`)**: It ranks cast members for each movie to identify lead actors.
3. **String Aggregation (`STRING_AGG`)**: It collects keywords associated with each movie.
4. **COALESCE with NULL Logic**: It handles situations where average note lengths may return NULL.
5. **Outer Joins**: It uses left joins to include movies even if they have no associated keywords or cast.
6. **Group By and Aggregations**: It summarizes data to count total cast and compute average note lengths.

These elements combine to provide a comprehensive view of the movies, their leads, and related keywords for performance analysis.
