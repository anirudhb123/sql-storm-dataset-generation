WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(c.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(pi.info::numeric) AS avg_rating,
    COUNT(DISTINCT mci.company_id) AS production_companies,
    MAX(m.date::date) AS latest_release_date,
    MIN(m.date::date) AS earliest_release_date
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mci ON mh.movie_id = mci.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    (SELECT DISTINCT movie_id, production_date FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'release date')) m ON mh.movie_id = m.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    AVG(pi.info::numeric) > 7.0
ORDER BY 
    mh.production_year DESC, cast_count DESC;


This query:
1. Uses a recursive CTE (`movie_hierarchy`) to build a hierarchy of movies, including linked movies.
2. Joins various tables to collect aggregated data, such as counting cast members, aggregating actor names, calculating average ratings, and counting production companies.
3. Filters results to only include movies whose average ratings exceed 7.
4. Orders the final output by production year and cast count.
