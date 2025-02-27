WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1 AS level
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
    FROM MovieHierarchy mh
    LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY mh.movie_id, mh.title
    HAVING COUNT(DISTINCT ci.person_id) > 5
),

PopularNames AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN TopMovies tm ON ci.movie_id = tm.movie_id
    GROUP BY ak.name
    HAVING COUNT(DISTINCT ci.movie_id) > 2
),

MovieInfo AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(mi.info SEPARATOR ', ') AS movie_information
    FROM movie_info mi
    JOIN TopMovies m ON mi.movie_id = m.movie_id
    GROUP BY m.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.roles_count,
    pn.movies_count AS popular_names_count,
    mi.movie_information
FROM TopMovies tm
LEFT JOIN PopularNames pn ON tm.title LIKE CONCAT('%', pn.name, '%')
LEFT JOIN MovieInfo mi ON tm.movie_id = mi.movie_id
ORDER BY tm.production_year DESC, total_cast DESC;


This SQL query performs complex operations to benchmark different SQL performance aspects, such as handling recursive CTEs, joining multiple tables with filters, and creating aggregations and conditions to extract relevant data.

1. **Recursive CTE:** `MovieHierarchy` builds a hierarchy of movies linked through `movie_link` for movies produced after the year 2000.

2. **Aggregating Movie Data:** The `TopMovies` CTE summarizes the number of cast members and roles per movie, filtering those that have more than 5 distinct cast members.

3. **Finding Popular Names:** The `PopularNames` CTE counts how many movies each actor has participated in, filtering actors involved in more than 2 of the previously calculated movies.

4. **Movie Information Aggregation:** The `MovieInfo` CTE gathers information about the selected movies.

5. **Final Presentation:** The final SELECT statement joins the previously built CTEs to provide a comprehensive report on the most popular titles, their cast size, roles created, the count of popular names associated with them, and additional movie-related information, ordered by production year and cast count.
