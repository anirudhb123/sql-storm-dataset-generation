WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_link ml ON ml.movie_id = t.id
    WHERE 
        ml.link_type_id = 1  -- Assuming 1 represents a certain type of linkage, e.g., sequel
    UNION ALL
    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title t ON t.id = ml.movie_id
    WHERE 
        ml.link_type_id = 1  -- Continuing the recursion for the same type of linkage
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
),
TopMovies AS (
    SELECT 
        *,
        COALESCE(LEFT(t.title, 10), 'Unknown Title') AS short_title,
        CASE 
            WHEN production_year IS NULL THEN 'Year Unknown'
            ELSE CAST(production_year AS VARCHAR)
        END AS production_year_display
    FROM 
        RankedMovies t
    WHERE 
        rn <= 5  -- Getting top 5 movies per hierarchy level
)
SELECT 
    tm.movie_id,
    tm.short_title,
    tm.production_year_display,
    ak.name AS actor_name,
    ti.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = tm.movie_id
LEFT JOIN 
    info_type ti ON ti.id = mi.info_type_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    ak.name IS NOT NULL  -- Ensures only movies with associated actors are displayed
ORDER BY 
    tm.level, 
    tm.production_year DESC;
