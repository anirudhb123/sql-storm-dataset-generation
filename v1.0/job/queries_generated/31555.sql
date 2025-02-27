WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COALESCE(ak.name, cn.name) AS actor_name,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        char_name cn ON ak.name IS NULL AND ci.role_id = cn.imdb_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = mh.movie_id) AS total_cast,
    cd.actor_name,
    cd.actor_order,
    mk.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year > 2000
ORDER BY 
    mh.production_year DESC, 
    mh.movie_id, 
    cd.actor_order
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;

This SQL query is designed to perform several complex operations:

1. It contains a **recursive CTE** (`MovieHierarchy`) to retrieve movies with their hierarchies (i.e., episodes and series).
2. It uses a **LEFT JOIN** to get actor details from the `cast_info`, `aka_name`, and `char_name` tables in the `CastDetails` CTE while also implementing **COALESCE** for null handling.
3. A separate CTE (`MovieKeywords`) aggregates keywords associated with each movie using **STRING_AGG**.
4. The final selection retrieves detailed information about each movie, counting the total cast while filtering for movies produced after the year 2000.
5. The results are paginated using **OFFSET** and **FETCH NEXT**, demonstrating further complexity in query results management.
6. Finally, the results are sorted by production year and actor order.
