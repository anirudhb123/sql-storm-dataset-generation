WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           0 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000 -- Filter for movies after the year 2000
    UNION ALL
    SELECT ml.linked_movie_id,
           mt.title,
           mt.production_year,
           mh.depth + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT a.name AS actor_name,
       count(DISTINCT c.movie_id) AS movies_count,
       AVG(mh.depth) AS avg_link_depth,
       string_agg(DISTINCT k.keyword, ', ') AS keywords,
       ARRAY_AGG(DISTINCT c.note) AS role_notes
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE a.name IS NOT NULL
GROUP BY a.name
HAVING COUNT(DISTINCT c.movie_id) > 5
ORDER BY movies_count DESC
LIMIT 10;

### Explanation:

1. **Recursive CTE (`MovieHierarchy`)**: This Common Table Expression builds a hierarchy of movies starting from those produced after the year 2000. The depth of the hierarchy is tracked to understand how these films may be linked to one another.

2. **Main Query**:
    - **Selecting Fields**:
        - The `actor_name` is fetched from `aka_name`.
        - The `movies_count` gives the number of distinct movies the actor has worked on.
        - The average linking depth (`avg_link_depth`) gauges how many links deep the actor's films are in the hierarchy defined by `MovieHierarchy`.
        - The aggregated keywords associated with all movies the actor participated in are collected in a comma-separated list.
        - Role notes are aggregated into an array of distinct notes.

3. **Joins**:
    - It joins the `cast_info` table to find all movies associated with an actor.
    - The `MovieHierarchy` is joined to limit results to movies that are part of the link structure.
    - Left joins are made to fetch keywords ensuring all movies are counted even if they don't have keywords associated.

4. **Filters**:
    - The query filters out actors with an unspecified name using `WHERE a.name IS NOT NULL`.
    
5. **Group By and Having**:
    - The results are grouped by actor names and the `HAVING` clause ensures that only those actors who have participated in more than five movies are returned.

6. **Ordering and Limiting**:
    - Finally, the results are ordered by the count of movies in descending order and limited to the top 10 actors fitting the criteria.
