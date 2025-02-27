WITH RECURSIVE MovieHierarchy AS (
    -- Base case: select all root movies with their corresponding companies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mc.company_id,
        cn.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY cn.name) AS company_rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    -- Recursive case: join based on linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        NULL AS company_id, -- Company details won't be carried through
        NULL AS company_name,
        NULL AS company_rank
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
)

SELECT 
    mh.movie_id,
    mh.title,
    STRING_AGG(DISTINCT mh.company_name, ', ') AS companies,
    COUNT(DISTINCT mci.id) AS total_cast_members,
    AVG(CASE WHEN ri.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_actors_in_roles,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    COALESCE(SUM(CASE WHEN ik.info_type_id IS NOT NULL AND ik.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    role_type ri ON ci.role_id = ri.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_info_idx ik ON mh.movie_id = ik.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mh.movie_id, mh.title
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
ORDER BY 
    total_cast_members DESC, 
    mh.title ASC
LIMIT 50;

This SQL query includes:
- A recursive Common Table Expression (CTE) to generate a hierarchy of movies and related company names.
- Outer joins to link various tables such as `complete_cast`, `cast_info`, `role_type`, `movie_keyword`, `movie_info`, and `movie_info_idx`.
- Window functions (ROW_NUMBER) to rank the companies associated with each movie.
- Aggregated string expressions (`STRING_AGG`) to combine company names into a single result string.
- Complicated filtering using `COALESCE`, `CASE` statements to calculate averages and counts.
- Grouping and ordering to synthesize the final results and limit the output.
- A HAVING clause to filter out movies without associated keywords.
