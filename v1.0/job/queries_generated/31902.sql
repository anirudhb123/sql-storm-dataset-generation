WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        cc.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link cc
    JOIN 
        MovieHierarchy mh ON cc.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON cc.linked_movie_id = mt.id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        RANK() OVER (PARTITION BY mh.level ORDER BY SUM(COALESCE(mci.note::integer, 0)) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        movie_info mci ON mc.movie_id = mci.movie_id AND mci.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    GROUP BY 
        mh.movie_id, mh.title, mh.level
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        row_number() OVER (PARTITION BY at.title ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON ci.movie_id = at.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.level,
    rm.rank AS movie_rank,
    ad.actor_name,
    ad.actor_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_title
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.level, rm.rank, ad.actor_rank;

### Explanation:
1. **Recursive CTE**: The query starts with a recursive Common Table Expression (CTE), `MovieHierarchy`, that builds a hierarchy of movies starting from those produced in the year 2000 and links to any movies they reference.

2. **RankedMovies CTE**: The second CTE, `RankedMovies`, ranks these movies by the cumulative budget obtained from the `movie_info` table. It ranks movies within each level of the hierarchy.

3. **ActorDetails CTE**: This CTE gathers the names of actors associated with each movie while assigning a rank for the actors within each movie.

4. **Final Selection**: The final select statement fetches and displays the movie ID, title, hierarchy level, rank, and actor details. It only shows the top 5 ranked movies at each level for clarity.

5. **NULL Handling**: The query uses `COALESCE` to handle any potential NULL values in the budget information from `movie_info`.

This complex query showcases various SQL features including recursive CTEs, rankings, and joining multiple tables with outer joins while filtering and grouping data thoughtfully.
