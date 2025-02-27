WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON mc.movie_id = t.movie_id
    JOIN 
        company_name AS cn ON cn.id = mc.company_id
    WHERE 
        cn.country_code = 'USA'
    
    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS t ON t.id = ml.linked_movie_id
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COUNT(ci.id) AS cast_count,
    AVG(CASE WHEN ci.notes IS NOT NULL THEN 1 ELSE 0 END) * 100 AS cast_note_percentage,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    SUM(CASE WHEN ti.id IS NOT NULL THEN 1 ELSE 0 END) AS info_count
FROM 
    MovieHierarchy AS h
LEFT JOIN 
    complete_cast AS cc ON cc.movie_id = h.movie_id
LEFT JOIN 
    cast_info AS ci ON ci.movie_id = h.movie_id
LEFT JOIN 
    movie_info AS mi ON mi.movie_id = h.movie_id
LEFT JOIN 
    movie_info_idx AS ti ON ti.movie_id = h.movie_id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = h.movie_id
LEFT JOIN 
    company_name AS cn ON cn.id = mc.company_id
WHERE 
    h.level = 0
GROUP BY 
    h.movie_id, h.title, h.production_year
ORDER BY 
    cast_count DESC, h.production_year DESC
LIMIT 50
OFFSET 0;

This SQL query accomplishes the following:
1. It sets up a recursive CTE called `MovieHierarchy` to retrieve movies produced in the USA and links them to any associated linked movies.
2. It then selects from this hierarchy to count the number of cast members, calculate the percentage of cast members who have notes, and aggregate the names of production companies.
3. The query includes various constructs like outer joins, aggregation, STRING_AGG for string concatenation, and complex predicates involving NULL checks.
4. It orders the result by the number of cast members in descending order and the production year in descending order, limiting the output to 50 rows.
