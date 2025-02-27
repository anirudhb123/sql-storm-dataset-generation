WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title mt
    INNER JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_title,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(ak.actor_count, 0) AS actor_count,
        COALESCE(mk.keyword_list, 'No keywords') AS keywords,
        mh.level
    FROM 
        MovieHierarchy mh
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT actor_id) AS actor_count
        FROM 
            ActorRoles
        GROUP BY 
            movie_id
    ) ak ON mh.movie_id = ak.movie_id
    LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    cm.movie_title,
    cm.production_year,
    cm.actor_count,
    cm.keywords,
    CASE 
        WHEN cm.actor_count = 0 THEN 'No Actors'
        WHEN cm.level > 0 THEN 'Episode'
        ELSE 'Standalone Movie'
    END AS movie_type,
    ROW_NUMBER() OVER (ORDER BY cm.production_year DESC) AS ranking
FROM 
    CompleteMovies cm
ORDER BY 
    cm.production_year DESC, cm.movie_title;

This SQL query accomplishes the following:

1. **Recursive CTE (`MovieHierarchy`)**: Constructs a hierarchy of movies and their episodes, allowing one to analyze standalone movies versus episode-linked titles.

2. **CTE for Actor Roles (`ActorRoles`)**: Joins actors with their corresponding movie roles while ensuring that each actor's roles are ranked by the order of appearance.

3. **CTE for Movie Keywords (`MovieKeywords`)**: Aggregates keywords associated with each movie, enhancing contextual understanding.

4. **Final CTE (`CompleteMovies`)**: Compiles all relevant information, such as the number of unique actors, keywords, and hierarchical levels for classification.

5. **Complex Select Statement**: The final output orders movies by their production years and categorizes them based on the number of actors and their episode status, employing `CASE` logic for flexible categorization and `ROW_NUMBER` for ranking.

The result set provides an interesting and comprehensive overview of movies, showcasing the intricacies of their relationships, keyword associations, and actor involvement.
