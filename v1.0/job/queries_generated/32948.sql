WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title at ON m.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
), 
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, production_year ASC) AS rank
    FROM 
        MovieDetails
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.actor_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10 
ORDER BY 
    tm.total_cast DESC, 
    tm.production_year ASC;

In this query:
- The `MovieHierarchy` CTE is used recursively to build a hierarchy of movies from the `aka_title` table.
- The second CTE, `MovieDetails`, aggregates data on the movies including the number of cast members and a concatenation of actor names.
- The `TopMovies` CTE ranks the movies based on total cast size and production year.
- Finally, the outer query selects the top 10 movies with the most cast members, ordering them by total cast size and their production year.
