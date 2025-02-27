WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    WHERE 
        m.country_code IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id, ci.movie_id
),
FilteredActors AS (
    SELECT 
        ar.person_id,
        ar.movie_id
    FROM 
        ActorRoles ar
    WHERE 
        ar.role_count > 2
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
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(fa.person_id, 0) AS actor_id,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredActors fa ON rm.movie_id = fa.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rn <= 10
)

SELECT 
    fr.title,
    fr.production_year,
    CASE 
        WHEN fr.actor_id = 0 THEN 'Uncredited Actor'
        ELSE (SELECT ak.name FROM aka_name ak WHERE ak.person_id = fr.actor_id LIMIT 1)
    END AS actor_name,
    fr.keywords
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.title;

### Explanation of the Query:

1. **CTEs Usage**:
   - **RankedMovies**: Retrieves ranked movie titles based on the production year and joins with movie companies to get the company name while filtering out the records without a country code.
   - **ActorRoles**: Groups the cast information by each actor and movie, counting the distinct roles they have played.
   - **FilteredActors**: Filters actors who have more than 2 distinct roles.
   - **MovieKeywords**: Aggregates keywords associated with each movie into a comma-separated string.

2. **Outer Joins**:
   - The `FinalResults` CTE combines the information from `RankedMovies`, `FilteredActors`, and `MovieKeywords` using left joins to ensure movies are retained even if no actor or keywords are found.

3. **Null Logic**:
   - Uses `COALESCE` to handle null values from the outer joins, assigning a default value for actor_id and keywords.

4. **Complicated Predicates**:
   - The outer query filters results to include only the top 10 ranked movies per production year.

5. **String Aggregation**:
   - The `STRING_AGG` function is used in the MovieKeywords CTE to concatenate multiple keywords for each movie.

6. **Bizarre Semantics**:
   - The case statement provides a whimsical twist by assigning a default name 'Uncredited Actor' when no actor is present for a movie.

This query offers a detailed performance benchmark while exploring various SQL constructs and semantic complexities.
