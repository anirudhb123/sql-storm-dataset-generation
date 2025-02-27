WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT CONCAT(mi.info_type_id, ': ', mi.info), '; ') AS movie_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    COALESCE(cd.company_name, 'Unknown Company') AS company_name,
    COALESCE(cd.company_type, 'Unknown Type') AS company_type,
    mi.movie_details,
    CONCAT('Year Rank: ', rm.year_rank, ' | Actor Count: ', COALESCE(ac.actor_count, 0)) AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.title_id = mi.movie_id
WHERE 
    rm.year_rank = 1  -- selecting top-ranking movies of each production year
ORDER BY 
    rm.production_year DESC, rm.title;

### Explanation:

1. **Common Table Expressions (CTEs)**: Used to create temporary result sets for ranking movies by year, counting distinct actors, retrieving company details, and aggregating movie information into a single string, making the query more modular and readable.

2. **Window Functions**: Utilized `ROW_NUMBER()` to assign a ranking to movies based on their production year. This allows us to target just the top-ranked movies from each year.

3. **LEFT JOINs**: Ensured all movies, even without actors or companies, are still included in the result set. This is done by left joining to actor details and company details.

4. **COALESCE**: Applied to handle NULLs, providing fallback values for company names/types when they don't exist.

5. **STRING_AGG()**: This aggregation function concatenates various details about the movie into a readable string.

6. **Complex Predicates**: Notably, in the `WHERE` clause, the numeric comparison is used to filter for the top movie from each year.

7. **Output Fields**: The SELECT statement presents a rich dataset, including the title, year, actor count, and company details, as well as additional concatenated information showcasing the ranking and actor count. 

8. **Order By**: The results are ordered by production year and title for clearer reading.

This query serves both analytical and performance benchmarking purposes, diving deep into the relationships between movies, actors, and companies.
