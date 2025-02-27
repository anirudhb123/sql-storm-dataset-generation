WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        at.production_year >= 2000
),
MovieCast AS (
    SELECT
        ci.movie_id,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names, -- Concatenate distinct actor names
        COUNT(ci.id) AS cast_count
    FROM
        cast_info ci
    JOIN
        aka_name an ON ci.person_id = an.person_id
    GROUP BY
        ci.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompleteMovieInfo AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mc.cast_names,
        mc.cast_count,
        mk.keywords
    FROM
        MovieHierarchy mh
    LEFT JOIN
        MovieCast mc ON mh.movie_id = mc.movie_id
    LEFT JOIN
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT
    cmi.movie_title,
    cmi.production_year,
    cmi.cast_names,
    COALESCE(cmi.cast_count, 0) AS total_cast,
    COALESCE(cmi.keywords, 'No Keywords') AS movie_keywords,
    mh.depth
FROM
    CompleteMovieInfo cmi
JOIN
    MovieHierarchy mh ON cmi.movie_id = mh.movie_id
WHERE
    COALESCE(cmi.production_year, 0) > 0
ORDER BY
    mh.depth DESC, cmi.production_year DESC;

This query does the following:

1. **Common Table Expressions (CTEs)**:
   - `MovieHierarchy`: Creates a recursive CTE to find movies linked to each other post-2000, establishing hierarchy based on linked movies.
   - `MovieCast`: Aggregates distinct cast member names and counts the number of cast members for each movie.
   - `MovieKeywords`: Aggregates keywords associated with each movie.

2. **CompleteMovieInfo CTE**: Combines data from the previously defined CTEs.

3. **Final Select**: Retrieves the movie title, production year, cast names, count of cast, keywords, and depth in hierarchy. It also provides default values for NULL results using `COALESCE`.

4. **Sorting**: The results are sorted by hierarchy depth and production year.
