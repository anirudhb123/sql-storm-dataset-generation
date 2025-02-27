WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COALESCE(at.season_nr, 0), at.episode_nr) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COALESCE(ai.info, 'No Info') AS additional_info,
        ar.movie_count,
        ar.roles
    FROM 
        aka_name ak
    LEFT JOIN 
        person_info ai ON ak.person_id = ai.person_id AND ai.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
    JOIN 
        ActorRoles ar ON ak.person_id = ar.person_id
)
SELECT 
    am.title,
    am.production_year,
    ad.actor_name,
    ad.additional_info,
    ad.movie_count,
    ad.roles
FROM 
    RankedMovies am
LEFT JOIN 
    complete_cast cc ON am.title_id = cc.movie_id
LEFT JOIN 
    ActorDetails ad ON cc.subject_id = ad.person_id
WHERE 
    am.title_rank <= 5
    AND (ad.roles IS NULL OR ad.roles LIKE '%Lead%')
ORDER BY 
    am.production_year DESC,
    ad.movie_count DESC,
    ad.actor_name ASC;

This SQL query is designed to perform a performance benchmark using various constructs, including Common Table Expressions (CTEs), window functions, joins, and filtering with intricate conditions. 

### Breakdown of the Query:
1. **RankedMovies CTE**: This CTE ranks movies by production year while ensuring that episodes are ordered by season and episode number. It filters for movies of the 'Drama' kind.

2. **ActorRoles CTE**: This CTE calculates the number of movies for each actor who has appeared in more than five films, along with their roles aggregated into a single string.

3. **ActorDetails CTE**: This retrieves actor names along with their biographies (if available) and movie counts, utilizing a left join to ensure actors without biography info are still included.

4. **Final SELECT statement**: This selects relevant information from the joined datasets - movies and actors - while implementing further constraints based on previously calculated ranks and role conditions.

5. **WHERE criteria**: Filter conditions make use of NULL conditions, ensuring that we still retrieve results even for actors with specific roles.

This query can serve as a benchmark for examining various SQL functionalities and performance implications, combining multiple patterns and potential corner cases in SQL logic.
