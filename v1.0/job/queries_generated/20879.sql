WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        mc.note IS NULL
),
CastInfo AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ak.surname_pcode,
        ct.kind AS role_kind,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM
        cast_info c
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        comp_cast_type ct ON c.person_role_id = ct.id
),
MovieStatistics AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors_list
    FROM
        CastInfo
    GROUP BY 
        movie_id
),
GenderStatistics AS (
    SELECT 
        p.gender,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        person_info p
    JOIN
        cast_info c ON p.person_id = c.person_id
    GROUP BY
        p.gender
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ci.company_name, 'Unknown') AS company_name,
    COALESCE(cs.actor_count, 0) AS total_actors,
    COALESCE(cs.actors_list, 'None') AS actors,
    gs.movie_count AS number_of_movies_by_gender,
    gs.gender
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    MovieStatistics cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    GenderStatistics gs ON gs.movie_count IS NOT NULL
WHERE 
    rm.title_rank <= 10
    AND (rm.production_year >= 2000 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC,
    rm.title ASC;

### Explanation:

1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Ranks movies based on their titles by production year, filtering out null years.
   - `CompanyInfo`: Retrieves company association details excluding those with notes, using INNER JOINs to connect the companies to movies.
   - `CastInfo`: Aggregates cast information, assigning a row number to actors in each movie, capturing their roles with optional character set joins.
   - `MovieStatistics`: Counts distinct actors per movie and lists their names.

2. **GenderStatistics**: Aggregates gendered data on how many movies feature actors of each gender.

3. **Final Selection**: The main query consolidates data from my CTEs, performing outer joins where data may be missing, applying COALESCE to handle null values. The result set is ordered by production year and title.

4. **Predicate Conditions**: Unique conditions are applied to filter the leading movies by title rank and conditionally on production years.

5. **String Aggregation**: Uses `STRING_AGG` to create a list of actors for each movie.

This showcases an elaborate SQL query combining multiple CTEs, joins, aggregates, and handling null logic with complexity in conditions and data retrieval, perfect for performance benchmarking use cases.
