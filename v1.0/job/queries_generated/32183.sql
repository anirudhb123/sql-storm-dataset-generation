WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000  -- Filtering for movies post-2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS ak ON ml.linked_movie_id = ak.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        ak.production_year >= 2000  -- To ensure hierarchy remains consistent
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_within_level
    FROM 
        MovieHierarchy AS mh
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        level
    FROM 
        RankedMovies
    WHERE 
        rank_within_level <= 5  -- Get top 5 movies at each hierarchy level
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ct.kind AS role_type,
        COUNT(ci.role_id) OVER (PARTITION BY ci.movie_id) AS total_cast
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type AS ct ON ci.person_role_id = ct.id
),
MovieWithCast AS (
    SELECT 
        trm.title,
        trm.production_year,
        trm.level,
        cd.actor_name,
        cd.role_type,
        cd.total_cast
    FROM 
        TopRankedMovies AS trm
    LEFT JOIN 
        CastDetails AS cd ON trm.movie_id = cd.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.level,
    COALESCE(mwc.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(mwc.role_type, 'N/A') AS role_type,
    mwc.total_cast,
    CASE 
        WHEN mwc.production_year < 2010 THEN 'Pre-2010'
        ELSE 'Post-2010'
    END AS era
FROM 
    MovieWithCast AS mwc
ORDER BY 
    mwc.level, 
    mwc.production_year DESC, 
    mwc.total_cast DESC;

This SQL query structure includes:

1. **Recursive CTE (Common Table Expression)**: `MovieHierarchy` to establish relationships between movies and sequels, filtering for films released after the year 2000.

2. **Window Function**: Used in `RankedMovies` to rank movies within each hierarchy level by production year.

3. **Filtering and Aggregation**: `TopRankedMovies` narrows down to the top 5 ranked movies per level.

4. **Outer Join**: The `LEFT JOIN` fetches actor details associated with movies, regardless of whether there are any actors listed.

5. **Coalesce and NULL Logic**: Use of `COALESCE` to handle NULL values in actor and role type fields, providing default values.

6. **Complex Predicate**: The final selection classifies movies as either pre-2010 or post-2010 based on the production year.

7. **Order By Clause**: The final result set is ordered first by hierarchy level, then by production year and total cast size.
