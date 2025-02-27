WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.movie_id = m.id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.linked_movie_id
)
, MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COUNT(c.person_id) AS cast_count,
        AVG(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON c.movie_id = mh.movie_id
    LEFT JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        mh.movie_id, mh.movie_title
)
SELECT 
    ms.movie_title,
    ms.cast_count,
    ms.avg_role,
    CASE 
        WHEN ms.roles IS NULL THEN 'No roles assigned'
        ELSE ms.roles
    END AS roles_summary,
    COALESCE(k.keyword, 'No keywords') AS keyword_summary
FROM 
    MovieStats ms
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ms.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
ORDER BY 
    ms.cast_count DESC, 
    ms.movie_title ASC
LIMIT 10;

### Explanation:
- **CTE `MovieHierarchy`:** Creates a recursive view of movies from the year 2000 onwards and their linked movies.
- **CTE `MovieStats`:** Aggregates data to count the number of cast members and calculate average assigned roles per movie, while also concatenating distinct roles into a string.
- **Final Select Statement:** Combines the results of the aggregated movie stats with keywords, utilizing outer joins to ensure all movies are included even if they don't have keywords or cast information, and applies COALESCE and conditional expressions for string summaries. The results are ordered by `cast_count` and `movie_title`, optimized for viewing the top movies by number of cast members.
