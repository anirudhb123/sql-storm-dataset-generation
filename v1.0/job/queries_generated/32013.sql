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
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)
SELECT 
    mk.keyword,
    count(DISTINCT mc.movie_id) AS total_movies,
    AVG(CASE 
            WHEN c.role_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS avg_roles,
    COUNT(DISTINCT CASE 
            WHEN p.gender = 'F' THEN p.person_id 
            END) AS female_actors,
    COUNT(DISTINCT CASE 
            WHEN p.gender = 'M' THEN p.person_id 
            END) AS male_actors,
    MAX(mh.production_year) AS latest_movie_year
FROM 
    movie_keyword mk
JOIN 
    aka_title m ON mk.movie_id = m.id
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    name p ON c.person_id = p.id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    total_movies DESC, avg_roles DESC;

This SQL query performs several tasks: 

1. It defines a recursive Common Table Expression (CTE) `MovieHierarchy` which collects movies produced from the year 2000 onwards and builds a hierarchy of episodes based on `episode_of_id`.

2. The main query uses various joins across multiple tables (`movie_keyword`, `aka_title`, `cast_info`, `name`, and the recursive CTE) to gather information on keywords associated with those movies.

3. It calculates the total number of movies for each keyword, the average number of roles associated with those movies, and counts the number of distinct female and male actors.

4. It also finds the latest production year among the movies linked to each keyword.

5. Lastly, it filters results to only include keywords that are associated with more than 5 movies, ordering the final output by the total number of movies and average roles in descending order.
