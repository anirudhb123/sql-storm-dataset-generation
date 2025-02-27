WITH RECURSIVE MovieHierarchy AS (
    -- 1: Find all movies and their respective titles
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    -- 2: Join to find linked movies (e.g., sequels)
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(c.role_id) AS number_of_roles,
    RANK() OVER (PARTITION BY mh.movie_id ORDER BY COUNT(c.role_id) DESC) AS role_rank,
    MAX(ci.note) FILTER (WHERE ci.note IS NOT NULL) AS note
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    company_name co ON mh.movie_id = (SELECT mc.movie_id FROM movie_companies mc WHERE mc.company_id = co.id LIMIT 1)
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    mh.production_year BETWEEN 1980 AND 2020
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(c.role_id) > 1
ORDER BY 
    mh.production_year DESC, role_rank
LIMIT 100;

### Explanation:
1. **CTE**: A recursive CTE (`MovieHierarchy`) retrieves all movies and their sequels (if any) by combining movies in the `aka_title` and links in the `movie_link` table.
2. **Joins**: Left joins to other tables to gather actor names, company information, additional details about each movie, and any notes about casting.
3. **Window Functions**: Uses `RANK()` to assign a rank to roles per movie based on the number of roles.
4. **Filtering**: Filters out movies by production year, ensuring that only movies produced between 1980 and 2020 are included.
5. **Aggregates**: Groups results to summarize the count of roles played by each actor in each film and filters for actors having played more than one role.
6. **Ordering**: Finally, it orders the results by production year and rank of roles for easy analysis.
7. **Limit**: Restricts the number of results returned to 100 for performance benchmarking.
