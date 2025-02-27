WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_number,
        COALESCE(mt.episode_nr, 0) AS episode_number,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        NULLIF(m.season_nr, 0),
        NULLIF(m.episode_nr, 0),
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id 
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
MovieInfoWithKeywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.season_number,
    mh.episode_number,
    cd.actor_name,
    cd.actor_order,
    mwk.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfoWithKeywords mwk ON mh.movie_id = mwk.movie_id
WHERE 
    mwk.keywords IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    mh.movie_title,
    cd.actor_order;

This SQL query performs the following tasks:

1. **Recursive CTE (Common Table Expression)**: The `MovieHierarchy` CTE builds a hierarchy of movies from the `aka_title` table for movies produced from the year 2000 onwards. It follows the links to find related movies.

2. **Subquery for Cast Details**: The `CastDetails` CTE retrieves the names of actors in each movie, assigning them an order based on their appearance (using `ROW_NUMBER()`).

3. **Movie Info with Keywords**: The `MovieInfoWithKeywords` CTE aggregates keywords related to each movie.

4. **Final Query**: This combines all the data:
   - It selects columns from the recursive CTE, cast details, and keyword information.
   - Only movies with associated keywords are included (`WHERE mwk.keywords IS NOT NULL`).
   - Results are ordered by the production year (descending) and movie title, along with the order of the actors.

The query effectively demonstrates various SQL features like joins, subqueries, common table expressions, window functions, and also utilizes advanced filtering and string aggregation techniques.
