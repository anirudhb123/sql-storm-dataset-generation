SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.gender AS actor_gender,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS number_of_production_companies,
    AVG(mi.info_length) AS avg_movie_info_length
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword kw ON mk.keyword_id = kw.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    person_info p ON a.person_id = p.person_id
WHERE
    t.production_year >= 2000 
    AND a.name LIKE 'A%'
GROUP BY
    a.name, t.title, c.nr_order, p.gender
HAVING
    COUNT(DISTINCT kw.id) > 2
ORDER BY
    t.production_year DESC, c.nr_order ASC;

### Explanation:
- **Selection**: The query retrieves the aka names of people, movie titles, cast order, actor gender, unique keywords associated with the movies, the count of production companies involved, and the average length of movie information entries.
- **Joins**: Various tables are joined to link names to their roles in movies, titles, related keywords, companies, and additional info about the people.
- **Filtering**: Only considers titles produced from the year 2000 onwards and those aka names that start with the letter 'A'.
- **Grouping and Aggregation**: The results are grouped by name, movie title, cast order, and actor gender, ensuring only those with more than two distinct keywords associated with their movies are included.
- **Ordering**: Finally, results are ordered by the production year in descending order and cast order in ascending order.
