WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COALESCE(COUNT(cc.id), 0) AS cast_count,
    AVG(CASE WHEN cc.nr_order IS NOT NULL THEN cc.nr_order ELSE 0 END) AS avg_role_order,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN mct.kind = 'Production' THEN 1 ELSE 0 END) AS produced_count,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS row_num
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    aka_title at ON cc.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_type mct ON mc.company_type_id = mct.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    at.production_year > 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.id, at.title, at.production_year
HAVING 
    COUNT(DISTINCT cc.person_role_id) > 1
ORDER BY 
    actor_name, production_year DESC;

### Explanation:
- **Recursive CTE (MovieHierarchy)**: This part constructs a hierarchy of movies by linking movies to their sequels, giving us a deeper view into movie relationships.
- **Joins**: Various joins are used to link actors, movies, keywords, and companies, ensuring we pull in all relevant data.
- **COALESCE**: Used to ensure we have a count even if there are no cast entries.
- **AVG**: Calculates the average order of roles for actors in those movies.
- **STRING_AGG**: Compiles keywords associated with each movie into a single string for easier reading.
- **SUM**: Counts how many movies were produced by a particular company type.
- **ROW_NUMBER**: This window function assigns a sequential number to each actor's movies based on the production year.
- **WHERE and HAVING**: Filters to include only movies produced after 2000 and actors that have played more than one role, making the query meaningful for performance benchmarking.
