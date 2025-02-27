WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorMovieInfo AS (
    SELECT
        a.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year AS year,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword), 'No keywords') AS keywords,
        COALESCE(SUM(ci.nr_order), 0) AS total_roles,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title mt ON ci.movie_id = mt.id
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        a.name, mt.title, mt.production_year
),
HighRatedMovies AS (
    SELECT
        movie_id,
        AVG(r.rating) AS avg_rating
    FROM
        ratings r  -- Assuming there's a ratings table for movie ratings
    WHERE
        r.rating IS NOT NULL
    GROUP BY
        movie_id
)
SELECT
    ami.actor_name,
    ami.movie_title,
    ami.year,
    hr.avg_rating,
    ami.total_roles,
    ami.noted_roles
FROM
    ActorMovieInfo ami
LEFT JOIN
    HighRatedMovies hr ON ami.movie_title = (SELECT title FROM aka_title WHERE id = hr.movie_id)
WHERE 
    hr.avg_rating >= 8.0
ORDER BY
    ami.year DESC,
    hr.avg_rating DESC,
    ami.total_roles DESC
LIMIT 50;

This query performs the following steps:

1. **Recursive CTE** (`MovieHierarchy`): Builds a hierarchy of movies linked together through `movie_link`.

2. **ActorMovieInfo CTE**: Aggregates information about actors, collecting their movie roles, production years, and associated keywords. It uses `COALESCE` to handle NULL values.

3. **HighRatedMovies CTE**: Calculates the average rating for each movie (assuming a `ratings` table exists).

4. The final SELECT statement retrieves actor names, movie titles, production years, average ratings, and counts of roles and noted roles — filtering for movies with an average rating of 8 or higher.

5. The output is sorted by year, then average rating, and total roles, focusing on the highest-rated movies from the most recent year. The LIMIT clause restricts the results to the top 50 records.
