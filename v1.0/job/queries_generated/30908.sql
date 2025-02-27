WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mk.linked_movie_id AS movie_id,
        mk.linked_movie_title AS movie_title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link mk ON mh.movie_id = mk.movie_id
    WHERE 
        mk.linked_movie_id IS NOT NULL
),

CastInfoWithRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),

MovieInfoWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),

FinalResults AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        ci.actor_name,
        ci.role_name,
        m.keywords,
        mh.depth
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastInfoWithRoles ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        MovieInfoWithKeywords m ON mh.movie_id = m.movie_id
    WHERE 
        (ci.role_name IS NOT NULL OR m.keywords IS NOT NULL)
)

SELECT 
    f.movie_id,
    f.movie_title,
    f.actor_name,
    f.role_name,
    f.keywords,
    f.depth
FROM 
    FinalResults f
ORDER BY 
    f.depth DESC, 
    f.movie_title;

### Explanation:
1. **Recursive CTE (MovieHierarchy)**: This CTE creates a hierarchy of movies developed from the year 2000 onward, detailing their interconnections through linked movies.
2. **CastInfoWithRoles CTE**: This CTE fetches a list of cast for each movie alongside their respective roles, including row numbering to maintain proper order.
3. **MovieInfoWithKeywords CTE**: This CTE pulls in keywords for each movie, concatenating them into a single string for readability.
4. **FinalResults CTE**: This merges the previous CTEs to produce a comprehensive result set that combines movie details, casts, roles, and keywords while allowing NULL values.
5. **Final SELECT Statement**: The final select arranges the output, prioritizing deeper movie connections and titles for easy navigation through the hierarchy.

The complex use of joins, CTEs, string aggregation, and filtering demonstrates a sophisticated querying mechanism suitable for performance benchmarking.
