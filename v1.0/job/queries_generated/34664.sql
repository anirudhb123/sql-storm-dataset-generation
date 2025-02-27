WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mk.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mt.title AS VARCHAR(255))
    FROM 
        movie_link mk
    JOIN 
        aka_title mt ON mk.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mk.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Limit to 3 levels of hierarchy
),

ActorRoleCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id
),

TopActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        arc.movie_count,
        arc.roles,
        ROW_NUMBER() OVER (ORDER BY arc.movie_count DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        ActorRoleCounts arc ON a.person_id = arc.person_id
    WHERE 
        arc.movie_count > 5  -- Only actors in more than 5 films
),

MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    ta.name AS top_actor,
    ta.movie_count,
    ta.roles,
    mk.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopActors ta ON ta.rank <= 3  -- Join to get top three actors per movie
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.production_year DESC, mh.level, mh.movie_id;
This SQL query performs several complex operations:

1. **Recursive Common Table Expression (CTE)** - `MovieHierarchy` builds a hierarchy of movies linked by a `movie_link`, limited to a depth of 3 levels.
  
2. **Subquery CTE** - `ActorRoleCounts` calculates the total number of movies for each actor and aggregates their roles into a string.

3. **Filtering Subquery CTE** - `TopActors` selects actors with more than 5 credited films, ranks them, and prepares for the main query.

4. **Keyword Aggregation CTE** - `MovieKeywords` collects all keywords related to each movie.

5. The **final SELECT** statement retrieves movie details alongside the top actors (with role information) and associated keywords, ordered by production year. 

6. The complex JOIN and NULL logic is utilized to ensure data integrity while retaining relationships across entities in the database schema.
