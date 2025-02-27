WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT
    a.name AS Actor_Name,
    COUNT(DISTINCT ci.movie_id) AS Number_of_Movies,
    COUNT(DISTINCT CASE WHEN mt.title IS NOT NULL THEN mt.movie_id END) AS Co_Acting_Movies,
    STRING_AGG(DISTINCT mt.title, ', ') AS Co_Acting_Titles,
    AVG(ACTIVE_RATINGS.rating) AS Avg_Rating,
    MAX(CASE WHEN ACTIVE_RATINGS.rating IS NOT NULL THEN ACTIVE_RATINGS.rating ELSE 0 END) AS Max_Rating
FROM
    aka_name a
LEFT JOIN
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(rating) AS rating
     FROM 
         movie_info
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
     GROUP BY 
         movie_id) AS ACTIVE_RATINGS 
    ON ci.movie_id = ACTIVE_RATINGS.movie_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title mt ON ci.movie_id = mt.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    Number_of_Movies < 10
ORDER BY 
    Number_of_Movies DESC, Avg_Rating DESC;

### Query Explanation:
- **CTE (Common Table Expression)**: A recursive CTE `MovieHierarchy` is created to manage movie relationships (e.g., sequels, remakes) by linking movies and their IDs via the `movie_link` table.
- **Main Query**: 
  - Joins `aka_name`, `cast_info`, and `MovieHierarchy` to pull actor names and movies they have acted in.
  - It also joins with an aggregate subquery to calculate average ratings for movies.
  - Uses `LEFT JOIN` with `movie_keyword` and `keyword` to get additional data if available, while ensuring NULL values are extensively handled.
- **Aggregations**:
  - Calculates counts, an aggregate function `STRING_AGG` for their movie titles, average, and maximum ratings.
- **Filtering**: Utilizes a `HAVING` clause to filter results to actors with fewer than 10 movies.
- **Ordering**: Finally sorts the results by the count of movies and average ratings in descending order.
