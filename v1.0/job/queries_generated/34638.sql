WITH RECURSIVE Movie_Hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Starting from the year 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        Movie_Hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5  -- Limit hierarchy depth to 5
)

SELECT
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(COALESCE(i.info::float, 0)) AS average_info_length,
    MAX(p.info) AS max_person_info,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    Movie_Hierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    ci.note IS NOT NULL 
    AND ci.nr_order IS NOT NULL
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 1 
    AND MAX(p.info) IS NOT NULL
ORDER BY 
    m.production_year DESC, average_info_length DESC;

### Explanation:
- **CTE (Common Table Expression):** A recursive CTE named `Movie_Hierarchy` is used to create a hierarchy of movies based on links between them, starting from movies produced since 2000.
  
- **Joins:** Various tables are joined (`cast_info`, `aka_name`, `movie_keyword`, `keyword`, `movie_info`, `info_type`, `movie_companies`, `company_type`) to gather data related to actors, movies, keywords, and companies involved in the movies.

- **Aggregation Functions:** The query counts distinct keywords per movie, averages the length of information entries, and finds the maximum personal information about actors.

- **String Aggregation:** It concatenates distinct company types involved with each movie.

- **Filtering and Grouping:** It ensures that only entries with non-null notes and order values from `cast_info` are included and groups results by actor names and titles.

- **Having Clause:** Filters groups to only include records with more than one associated keyword and ensures that the maximum person information is not NULL.

- **Order By Clause:** Results are sorted first by production year in descending order and then by average information length in descending order.
