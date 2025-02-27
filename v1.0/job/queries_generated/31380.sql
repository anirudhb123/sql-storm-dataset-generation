WITH RECURSIVE MovieChain AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS chain_level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
    
    UNION ALL
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        mc.chain_level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        MovieChain mc ON ml.movie_id = mc.linked_movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT mci.person_id) AS cast_count,
    CAST(ROUND(AVG(CASE 
            WHEN ci.role_id IS NOT NULL THEN 1 
            ELSE 0 
        END), 2) AS DECIMAL(5, 2)) AS average_roles_per_actor,
    string_agg(DISTINCT a.name, ', ') AS main_actors,
    CASE 
        WHEN COUNT(DISTINCT mci.movie_id) > 1 THEN 'Part of a Series'
        ELSE 'Standalone'
    END AS movie_type,
    MAX(k.keyword) AS keyword_associated
FROM 
    title m
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieChain mc ON mc.movie_id = m.id
GROUP BY 
    m.id
HAVING 
    COUNT(DISTINCT mc.linked_movie_id) > 0
ORDER BY 
    m.production_year DESC, cast_count DESC;

### Explanation of the Query:

1. **CTE (Recursive)**: The `MovieChain` CTE builds a chain of movies that are linked as sequels, allowing the query to analyze movies and their sequels in a hierarchy.

2. **Selection**: The main query selects the `title`, `production_year`, and counts distinct actors in the cast.

3. **Aggregations**: 
   - It calculates the average number of roles per actor.
   - It uses `string_agg` to gather all unique actor names for each movie.
   - It categorizes the movie as either part of a series or a standalone film based on the presence of linked movies.

4. **LEFT JOINs**: Multiple tables are joined together, ensuring even movies without a complete cast or keywords are included.

5. **HAVING Clause**: Filters results to only include movies that are part of a sequel chain.

6. **ORDER BY**: The results are ordered by the production year and the number of distinct cast members.

This query captures multiple facets of the dataset, involving various SQL constructs, aimed at performance benchmarking.
