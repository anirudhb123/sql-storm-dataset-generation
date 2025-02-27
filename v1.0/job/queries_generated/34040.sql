WITH RECURSIVE MovieHierarchy AS (
    -- CTE to recursively get movie details along with their associated companies
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        c.name AS company_name,
        1 AS level 
    FROM 
        title m 
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id 
    LEFT JOIN 
        company_name c ON c.id = mc.company_id 
    WHERE 
        m.production_year IS NOT NULL 

    UNION ALL 

    SELECT 
        p.movie_id,
        m.title,
        m.production_year,
        c.name AS company_name,
        level + 1 
    FROM 
        MovieHierarchy p 
    INNER JOIN 
        movie_companies mc ON mc.movie_id = p.movie_id 
    INNER JOIN 
        company_name c ON c.id = mc.company_id 
    INNER JOIN 
        title m ON m.id = p.movie_id 
)

SELECT 
    t.title,
    t.production_year,
    string_agg(DISTINCT c.name, ', ') AS companies,
    COUNT(DISTINCT ca.person_id) AS num_actors,
    COUNT(DISTINCT kw.keyword) AS num_keywords,
    SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS num_info_type,
    AVG(CASE WHEN co.role_id IS NOT NULL THEN 1 ELSE NULL END) OVER (PARTITION BY t.id) AS avg_roles
FROM 
    title t 
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id 
LEFT JOIN 
    company_name c ON c.id = mc.company_id 
LEFT JOIN 
    complete_cast cc ON cc.movie_id = t.id 
LEFT JOIN 
    cast_info ca ON ca.movie_id = t.id 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id 
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id 
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id 
LEFT JOIN 
    role_type co ON co.id = ca.role_id 
WHERE 
    t.production_year BETWEEN 1990 AND 2023 
GROUP BY 
    t.id, t.title, t.production_year 
ORDER BY 
    t.production_year DESC, num_actors DESC; 

This query does the following:
- Creates a recursive CTE (`MovieHierarchy`) to explore the association between movies and production companies.
- Joins several tables: `title`, `movie_companies`, `company_name`, `complete_cast`, `cast_info`, `movie_keyword`, `keyword`, and `movie_info` to gather various information.
- Utilizes the `string_agg` function to aggregate company names associated with each movie.
- Counts distinct actors and keywords related to each film.
- Uses a window function to calculate the average role ID count per movie.
- Applies filters on production years (from 1990 to 2023) and groups results for the final output, ordered by year and number of actors.
