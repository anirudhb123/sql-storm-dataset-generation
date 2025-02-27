WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title AS movie_title, m.production_year, 0 AS hierarchy_level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title AS movie_title, m.production_year, mh.hierarchy_level + 1
    FROM aka_title m
    INNER JOIN movie_link ml ON m.id = ml.movie_id
    INNER JOIN MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)

, CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(CASE WHEN ci.note IS NOT NULL THEN 1 END) AS total_cast_members,
        COUNT(DISTINCT ci.person_id) AS distinct_persons,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    cs.total_cast_members,
    cs.distinct_persons,
    cs.avg_order,
    cs.actors_names,
    CASE 
        WHEN cs.total_cast_members > 10 THEN 'Large Cast'
        WHEN cs.total_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    COALESCE(cs.actors_names, 'No cast info available') AS display_actors
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastStatistics cs ON mh.movie_id = cs.movie_id
WHERE 
    mh.production_year > (SELECT AVG(production_year) FROM aka_title WHERE production_year IS NOT NULL) 
    OR mh.movie_title LIKE '%Adventure%'
ORDER BY 
    mh.production_year DESC,
    cs.total_cast_members DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation of SQL Constructs:
1. **Common Table Expressions (CTEs)**: Utilized `MovieHierarchy` to recursively gather linked movies and their titles, enabling mapping of related films across hierarchies.
2. **Aggregation**: Used the `CastStatistics` CTE to calculate total cast members, distinct persons, average order, and a concatenated list of actor names.
3. **CASE Statement**: Categorizes the size of the cast based on the number of cast members, allowing insights into movie scaling.
4. **LEFT JOIN**: This helps include movies even when there are no cast members present, preserving movie listings in the result.
5. **COALESCE**: Provides a fallback string when actor information is unavailable.
6. **Subquery predicates**: Used in the WHERE clause to filter movies produced after the average production year, or those with ‘Adventure’ in the title.
7. **ORDER BY and FETCH FIRST**: Limits the results to the top 10 recent movies while sorting first by production year and then by total cast members.

This query leverages complex SQL capabilities to derive a meaningful analysis of movie cast structures relative to their production attributes, making it a great benchmark for performance testing.
