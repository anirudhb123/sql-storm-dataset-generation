WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL -- Start with root movies (not episodes)

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.kind_id,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id -- Join with episodes
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT cc.id) AS total_cast_members,
    SUM(CASE WHEN i.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(CASE WHEN c.kind IS NOT NULL THEN c.kind END) AS company_type,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS actor_movie_rank
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info i ON m.movie_id = i.movie_id
WHERE 
    m.production_year IS NOT NULL
    AND (m.kind_id IN (SELECT k.id FROM kind_type k WHERE k.kind IN ('movie', 'series')) OR m.kind_id IS NULL)
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 1
ORDER BY 
    actor_movie_rank;

### Explanation

1. **CTE (Common Table Expression)**: A recursive CTE named `MovieHierarchy` generates a hierarchy of movies where the root is a movie without episodes, and recursively includes episodes designated by the `episode_of_id`.

2. **Main Query**:
   - Joins `aka_name` (actor names) with `cast_info` to link actors to their movies.
   - Joins the CTE to get movie details, linking it with the cast.
   - Uses left joins to obtain company information and movie keywords.
  
3. **Aggregations**:
   - Counts distinct cast members and sums movie info count.
   - Uses `STRING_AGG` to collect keywords associated with each movie.

4. **Window Function**: `ROW_NUMBER()` is used to rank movies for each actor based on the production year, allowing sorting within the output.

5. **Filtering Conditions**: It filters movies that are either of a certain kind or unspecified, and ensures that it only counts movies with more than one cast member.

This SQL query serves to benchmark performance while being complex enough to engage various SQL constructs and demonstrate data relationships effectively.
