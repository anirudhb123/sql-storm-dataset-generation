WITH RECURSIVE movie_hierarchy AS (
    -- Step 1: Build a recursive CTE to find all related movies
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Filter for movies released from the year 2000 onwards

    UNION ALL

    -- Step 2: Join recursively to find linked movies
    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        a.production_year >= 2000  -- Ensure we're linking to relevant movies
),
actor_movie_stats AS (
    -- Step 3: Aggregate movie stats per actor
    SELECT 
        ka.person_id,
        COUNT(DISTINCT ka.movie_id) AS movie_count,
        AVG(CASE WHEN a.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio,
        STRING_AGG(DISTINCT at.title, ', ') AS movies
    FROM 
        cast_info ka
    LEFT JOIN 
        movie_hierarchy mh ON ka.movie_id = mh.movie_id
    LEFT JOIN 
        aka_title at ON mh.movie_id = at.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = ka.movie_id
    GROUP BY 
        ka.person_id
),
top_actors AS (
    -- Step 4: Rank actors by their movie count
    SELECT 
        ai.id AS actor_id,
        ak.name,
        ams.movie_count,
        RANK() OVER (ORDER BY ams.movie_count DESC) AS movie_rank
    FROM 
        aka_name ak
    JOIN 
        actor_movie_stats ams ON ak.person_id = ams.person_id
    JOIN 
        name ai ON ak.person_id = ai.imdb_id
)
-- Final query: Select top 10 actors with their movie stats
SELECT 
    ta.actor_id,
    ta.name,
    ta.movie_count,
    ta.movie_rank,
    COALESCE(ta.movies, 'No Movies') AS movie_titles
FROM 
    top_actors ta
WHERE 
    ta.movie_rank <= 10  -- Retrieve the top 10 actors
ORDER BY 
    ta.movie_rank;
