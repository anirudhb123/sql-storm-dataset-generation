WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ch.name) AS character_count,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(m.production_year) AS average_production_year,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    MAX(mh.level) AS max_hierarchy_level
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    char_name ch ON ci.person_role_id = ch.id
CROSS JOIN 
    movie_keyword mk
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2 AND
    AVG(m.production_year) <= 2015;

### Explanation:
- **Recursive CTE (Common Table Expression)**: `MovieHierarchy` retrieves movies from the year 2000 onwards and their linked movies, building a hierarchy of movie links.
- **Joins**: The query involves multiple joins to connect people (actors), their roles, and movie metadata, including outer joins to ensure that all relevant data is accounted for.
- **Aggregation**: Using `COUNT`, `AVG`, and `STRING_AGG` to summarize data. This provides insights into the actor's contributions, character count, and associated keywords.
- **HAVING clause**: Filters results to show only actors involved in more than two movies and computes the average production year.
- **NULL Handling**: The condition `ak.name IS NOT NULL` ensures that we only consider actors with valid names.
- **Window Functions**: This query does not explicitly use window functions, but it can be modified to include them for additional ranking or partitioning requirements.
- **Complexities**: By including movie hierarchy and keywords, the query becomes intricate and thorough, providing a holistic view of an actor's filmography and contributions.
