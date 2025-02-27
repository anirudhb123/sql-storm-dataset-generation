WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title t
    INNER JOIN 
        movie_link ml ON ml.linked_movie_id = t.id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(cast_info.person_id, 'Unknown') AS actor_id,
    COALESCE(a.name, 'Not Available') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(mk.weight) AS total_keyword_weight,
    RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_within_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info cast_info ON cast_info.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = cast_info.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, cast_info.person_id, a.name
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mh.level, mh.production_year DESC;
This SQL query uses:

- **Recursive CTE** (`MovieHierarchy`) to build a hierarchy of movies and their linked sequels or prequels.
- **LEFT JOINs** to collect related data from various tables including `complete_cast`, `cast_info`, `aka_name`, `movie_companies`, and `movie_keyword`.
- **Aggregate functions** like `COUNT` and `STRING_AGG` to summarize data related to companies and keywords.
- **Window function** `RANK()` to rank movies within their hierarchical levels based on the production year.
- **NULL handling** using `COALESCE` to provide default values where necessary.
- **Complex predicates** in the `HAVING` clause to filter results with specific conditions. 

This offers a comprehensive view of movies, their actors, the companies involved, keywords associated with them, and ranks by production year.
