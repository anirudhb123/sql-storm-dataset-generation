WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS hierarchy_level 
    FROM 
        aka_title AS mt 
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ll.linked_movie_id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mh.hierarchy_level + 1 
    FROM 
        MovieHierarchy AS mh 
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id 
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id 
)
, ActorRoles AS (
    SELECT 
        p.id AS person_id, 
        a.name AS actor_name, 
        r.role AS role_name, 
        COUNT(c.movie_id) AS movies_count
    FROM 
        cast_info AS c 
    JOIN 
        aka_name AS a ON a.person_id = c.person_id 
    JOIN 
        role_type AS r ON c.role_id = r.id 
    GROUP BY 
        p.id, a.name, r.role 
    HAVING 
        COUNT(c.movie_id) > 5
)
, MovieKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword AS m 
    JOIN 
        keyword AS k ON m.keyword_id = k.id 
    GROUP BY 
        m.movie_id
)
SELECT 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    COALESCE(ak.actor_name, 'No Actor') AS actor_name,
    COALESCE(ar.role_name, 'Unknown Role') AS role_name,
    COALESCE(mk.keywords_list, 'No Keywords') AS keywords,
    mh.hierarchy_level,
    CASE WHEN mh.hierarchy_level > 2 THEN 'Deep Link'
         ELSE 'Shallow Link' END AS link_type
FROM 
    MovieHierarchy AS mh 
LEFT JOIN 
    ActorRoles AS ar ON mh.movie_id = ar.movies_count 
LEFT JOIN 
    MovieKeywords AS mk ON mh.movie_id = mk.movie_id 
ORDER BY 
    mh.production_year DESC, mh.title ASC
LIMIT 100;

This query accomplishes the following:

1. **Recursive CTE for Movie Hierarchy**: The `MovieHierarchy` CTE retrieves all movies and their linked movies, building a hierarchy based on their connections.

2. **Subquery for Actor Roles**: The `ActorRoles` CTE extracts actors who have featured in more than five movies. It collects actor names along with their respective roles.

3. **Keywords Aggregation**: The `MovieKeywords` CTE gathers keywords associated with movies, using the `STRING_AGG` function for aggregation.

4. **Main Query with Joins**: The main query combines the data from the hierarchy of movies, actor roles, and movie keywords, ensuring that if any actor or keyword isn't available, it substitutes with appropriate placeholder text.

5. **Complex Logic**: This query incorporates NULL handling with the `COALESCE` function and categorizes movie links based on their hierarchy level, adding semantic significance.

6. **Order and Limit Results**: Finally, it orders movies by production year and title while limiting the output to 100 rows for performance benchmarking.
