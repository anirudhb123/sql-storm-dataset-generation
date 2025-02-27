WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL 

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.depth < 3
)

SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(GROUP_CONCAT(DISTINCT a.name), 'None') AS Actors,
    COUNT(DISTINCT mc.company_id) AS Production_Companies,
    COUNT(DISTINCT mk.keyword) AS Keywords,
    AVG(person_info.info) FILTER (WHERE person_info.info_type_id = 1) AS Average_Info_Type_1  -- Assuming 1 corresponds to a meaningful info type
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    person_info ON c.person_id = person_info.person_id
GROUP BY 
    m.movie_id, m.title, m.production_year
ORDER BY 
    m.production_year DESC
HAVING 
    COUNT(DISTINCT a.id) > 1
    AND AVG(person_info.info) IS NOT NULL
    AND m.production_year IS NOT NULL;

### Explanation:
- **CTE (Recursive)**: The `movie_hierarchy` CTE recursively retrieves movies and their hierarchical relationships, going through links up to three levels deep.
- **Left Joins**: Used to gather related data about cast members, production companies, and keywords without excluding movies that may not have all these details.
- **Aggregate Functions**: Used to count production companies and keywords while averaging a specific type of personal information.
- **Having Clause**: Filters results to include only those movies with more than one actor and valid average personal information.
- **Coalesce and Group_Concat**: Ensures that if there are no actors, a default 'None' is shown. Grouping actors by their names allows for a compact representation of the cast.
- **Predicates**: Filters and conditions specify which movies are selected based on production details and relationships established through left joins.
