-- Performance benchmarking query with complex constructs
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        c.nr_order,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IN ('actor', 'actress')
        AND c.note IS NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
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
        rc.person_id,
        rc.nr_order,
        rc.role_name,
        cs.company_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT rc.person_id) OVER (PARTITION BY rm.production_year) AS total_actors_year
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredCast rc ON rm.movie_id = rc.movie_id
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.person_id,
    fr.role_name,
    fr.company_count,
    fr.keywords,
    fr.total_actors_year
FROM 
    FinalResults fr
WHERE 
    fr.year_rank = 1 
    AND fr.company_count IS NOT NULL
    AND fr.keywords NOT LIKE '%Ghost%'
ORDER BY 
    fr.production_year DESC,
    fr.company_count DESC;

This SQL query includes:

- **Common Table Expressions (CTEs)**: Used to break down the query into manageable parts for ranking movies, filtering cast members, counting companies per movie, and aggregating keywords.
- **Window Functions**: Employed to assign a rank to movies by production year and to count actors.
- **LEFT JOINs**: Used to ensure that we still get movies even if they have no associated cast, companies, or keywords.
- **COALESCE**: To handle cases where there are no keywords by providing a default string.
- **Complicated predicates**: Features predicates that check for NULL values, which can lead to interesting edge cases and filters related to presence and absence of data.
- **String Aggregation**: Collects keywords into a single field, which can be useful for performance summaries.
- **String matching**: Excludes keywords containing "Ghost", indicating a specific business case.
- **Ordering**: Results are sorted by production year and the count of companies involved. 

This query aims to explore complex relationships among various entities while also ensuring performance through structured rankings and aggregations.
