WITH RecursiveActorCount AS (
    SELECT 
        c.person_id, 
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM cast_info c
    LEFT JOIN complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY c.person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
),
CompaniesInvolved AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
FilteredMovies AS (
    SELECT
        mt.movie_id,
        mt.title,
        mt.keywords,
        ci.company_count,
        ci.company_names
    FROM MoviesWithKeywords mt
    JOIN CompaniesInvolved ci ON mt.movie_id = ci.movie_id
    WHERE ci.company_count > 1 AND mt.keywords IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        r.role, 
        COUNT(c.movie_id) AS roles_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.person_id, r.role
),
ActorStats AS (
    SELECT 
        ac.person_id,
        ac.movie_count,
        MAX(ar.roles_count) AS max_roles,
        MIN(ar.roles_count) AS min_roles,
        AVG(ar.roles_count) AS avg_roles
    FROM RecursiveActorCount ac
    LEFT JOIN ActorRoles ar ON ac.person_id = ar.person_id
    GROUP BY ac.person_id, ac.movie_count
)
SELECT 
    DISTINCT f.title,
    f.keywords,
    CAST(a.person_id AS VARCHAR) AS actor_id,
    a.movie_count,
    a.max_roles,
    a.min_roles,
    a.avg_roles,
    CASE 
        WHEN a.movie_count IS NULL THEN 'No movies'
        ELSE 'Active Actor'
    END AS actor_status
FROM FilteredMovies f
LEFT JOIN ActorStats a ON f.movie_id IN (SELECT DISTINCT movie_id FROM cast_info WHERE person_id = a.person_id)
WHERE f.keywords @> ARRAY['action'] -- Only movies tagged with 'action'
   OR f.title ILIKE '%adventure%' -- or titles that contain 'adventure'
ORDER BY f.title
FETCH FIRST 100 ROWS ONLY;

This SQL query performs an elaborate performance benchmarking operation through the following steps:

1. **RecursiveActorCount**: Counts the number of movies per actor.
2. **MoviesWithKeywords**: Aggregates keywords associated with each movie.
3. **CompaniesInvolved**: Counts how many companies are associated with each movie.
4. **FilteredMovies**: Filters movies that involve more than one company and have keywords.
5. **ActorRoles**: Counts the number of roles each actor has played.
6. **ActorStats**: Aggregates maximum, minimum, and average roles per actor.
7. Finally, it selects distinct titles from `FilteredMovies`, providing actor stats, filtering on movies that either have 'action' as a keyword or 'adventure' in the title, and ordering the results.

This query challenges various SQL functionalities while adhering to complex predicates and utilizing multiple layers of aggregation, thereby reflecting an intricate structure typical of sophisticated performance benchmarking queries.
