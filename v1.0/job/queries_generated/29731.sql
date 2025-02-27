SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    STRING_AGG(DISTINCT c.kind ORDER BY c.kind) AS company_types,
    COUNT(DISTINCT ci.id) AS total_cast_members
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type AS c ON mc.company_type_id = c.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 1990 AND 2023
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    total_cast_members DESC, movie_title;

This SQL query aggregates and benchmarks string processing capabilities by:

- Selecting actor names, movie titles, production years, associated keywords, company types, and counting total cast members.
- Joining multiple tables to collate relevant data, ensuring that it retrieves meaningful associations about actors, movies, and their related keywords and companies.
- Utilizing functions like `GROUP_CONCAT` and `STRING_AGG` to efficiently concatenate strings from multiple rows.
- Including a date filter in the `WHERE` clause to target movies released between 1990 and 2023.
- Resulting rows are grouped by actor name, movie title, and production year, while ordering the final result by the total count of cast members and movie title for better readability.
