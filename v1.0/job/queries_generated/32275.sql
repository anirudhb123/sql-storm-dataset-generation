WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL  -- Starting from top-level movies (not episodes)

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        title t
    JOIN 
        movie_link ml ON t.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregatedCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
TitleInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(ag.actor_count, 0) AS actor_count,
        ag.actor_names
    FROM 
        title t
    LEFT JOIN 
        AggregatedCast ag ON t.id = ag.movie_id
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
    th.movie_id,
    th.title,
    th.production_year,
    th.actor_count,
    th.actor_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords_indicators,
    mh.level AS hierarchy_level
FROM 
    TitleInfo th
LEFT JOIN 
    MovieKeywords mk ON th.movie_id = mk.movie_id
JOIN 
    MovieHierarchy mh ON th.movie_id = mh.movie_id
WHERE 
    th.production_year >= 2000  -- Filtering on recent movies
ORDER BY 
    th.production_year DESC,
    th.actor_count DESC,
    mh.level ASC;

This SQL query creates a recursive common table expression (CTE) to establish a hierarchy of films and episodes. It aggregates cast information to get actor counts and names, collects keywords for films, and then retrieves and orders movie details based on various criteria, providing a comprehensive overview of recent movies in relation to their cast and keyword associations.
