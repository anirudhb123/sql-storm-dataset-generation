WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM title t
    JOIN aka_title a ON a.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year >= 2000
      AND k.keyword IN ('Action', 'Adventure')

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        m.production_year,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN title t ON t.id = ml.linked_movie_id
    JOIN aka_title a ON a.movie_id = t.id
    WHERE mh.level < 3
      AND t.production_year >= 2000
)

SELECT 
    m.id AS movie_id,
    MAX(mh.level) AS max_depth,
    t.title,
    COUNT(DISTINCT p.id) AS actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM MovieHierarchy mh
JOIN title t ON t.id = mh.movie_id
LEFT JOIN movie_info mi ON mi.movie_id = t.id
LEFT JOIN cast_info ci ON ci.movie_id = t.id
LEFT JOIN aka_name a ON a.person_id = ci.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN person_info pi ON pi.person_id = ci.person_id
WHERE pi.info IS NOT NULL
GROUP BY m.id, t.title
HAVING COUNT(DISTINCT ci.id) > 5
ORDER BY max_depth DESC, actor_count DESC;

### Explanation:

- **Common Table Expressions (CTEs)**: A recursive CTE named `MovieHierarchy` is created to track movies and their linked movies while maintaining a level of depth.

- **Joins**: Various tables such as `title`, `aka_title`, `movie_link`, `cast_info`, `aka_name`, and `movie_keyword` are joined to gather information related to actors, titles, and keywords associated with each movie.

- **Aggregations**: The final SELECT statement calculates `max_depth`, the number of unique actors, as well as how many notes are present, along with the count of distinct keywords for each movie.

- **STRING_AGG**: This function is used to concatenate the names of the actors involved in each movie.

- **HAVING Clause**: The query filters the results to include only those movies that feature more than 5 distinct cast members.

- **Ordering**: Finally, the results are ordered by the maximum depth of the movie hierarchy followed by actor count in descending order. 

This complex query is ideal for performance benchmarking as it combines multiple SQL constructs and showcases relational dynamics with a potentially large dataset.
