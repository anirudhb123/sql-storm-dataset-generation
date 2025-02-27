WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title t 
    JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        cn.country_code = 'USA' AND 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh 
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    WHERE 
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'Sequel')
),
ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        MovieHierarchy mh ON mh.movie_id = c.movie_id
    GROUP BY 
        c.person_id
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        am.movie_count,
        ROW_NUMBER() OVER (PARTITION BY am.movie_count ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    LEFT JOIN 
        ActorMovieCount am ON a.person_id = am.person_id
)
SELECT 
    ad.actor_id,
    ad.name,
    ad.movie_count,
    COALESCE(ad.actor_rank, 0) AS actor_rank
FROM 
    ActorDetails ad
WHERE 
    ad.movie_count IS NOT NULL
ORDER BY 
    ad.movie_count DESC,
    ad.name ASC
LIMIT 10;

This SQL query does the following:

1. **Recursive CTE** - `MovieHierarchy`: This CTE starts with movies from the USA produced from the year 2000 onward, and recursively finds sequels for those movies. It builds a hierarchical structure of sequels.

2. **Aggregation CTE** - `ActorMovieCount`: This CTE counts the number of distinct movies each actor has been in that are part of the previously defined hierarchy.

3. **Details CTE** - `ActorDetails`: This gathers the actor names along with their movie counts and ranks them within their respective movie counts using a window function.

4. **Final Selection**: The main query filters for actors who have movies in the hierarchy and orders them by movie count, ensuring that the top actors by roles are displayed. It limits the results to the top 10 actors.
