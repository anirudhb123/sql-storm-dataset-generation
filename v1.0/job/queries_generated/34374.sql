WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.kind_id = 1  -- Assuming kind_id 1 represents 'movie'

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS num_actors,
    STRING_AGG(DISTINCT ak.name, '; ') AS actor_names,
    AVG(mo.info_length) AS avg_info_length
FROM MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN (
    SELECT 
        mi.movie_id,
        AVG(LENGTH(mi.info)) AS info_length
    FROM movie_info mi
    GROUP BY mi.movie_id
) mo ON mh.movie_id = mo.movie_id
LEFT JOIN aka_name ak ON ak.person_id = ca.person_id
WHERE mh.production_year >= 2000
GROUP BY mh.movie_id, mh.title, mh.production_year
ORDER BY mh.production_year DESC, num_actors DESC
LIMIT 50;

### Explanation:
- **CTE (Common Table Expression)**: A recursive CTE called `MovieHierarchy` is created to retrieve movies and their linked counterparts.
- **JOINs**: Various left joins are used to aggregate data from the `complete_cast`, `cast_info`, `movie_info`, and `aka_name` tables. This allows us to fetch actor information and additional movie details.
- **Aggregation**: The query counts the unique actors for each movie and concatenates their names, while also calculating the average length of information strings related to each movie.
- **WHERE Clause**: A filter is applied to only consider movies produced from the year 2000 onward.
- **ORDER BY and LIMIT**: The results are ordered by production year (descending) and then by the number of actors (also descending), with a limit of 50 results.
