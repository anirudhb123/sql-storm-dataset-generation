WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MoviesWithKeywords AS (
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
),
ExpandedMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rn <= 5 -- To limit to the first 5 movies per year
),
ComplicatedJoin AS (
    SELECT 
        em.title,
        em.production_year,
        em.actor_count,
        em.keywords,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        ct.kind AS company_type
    FROM 
        ExpandedMovies em
    LEFT JOIN 
        movie_companies mc ON em.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
NullLogicExample AS (
    SELECT 
        title,
        production_year,
        actor_count,
        keywords,
        CASE 
            WHEN actor_count > 10 THEN 'Many Actors'
            WHEN actor_count IS NULL THEN 'No Actors'
            ELSE 'Few Actors'
        END AS actor_summary
    FROM 
        ComplicatedJoin
)
SELECT 
    title,
    production_year,
    actor_count,
    keywords,
    actor_summary
FROM 
    NullLogicExample
WHERE 
    (production_year >= 2000 AND actor_count IS NOT NULL)
    OR (keywords LIKE '%Action%' AND actor_summary = 'Few Actors')
ORDER BY 
    production_year DESC, 
    actor_count DESC;

This SQL query performs several complex operations, including:

1. **Common Table Expressions (CTEs)** for breaking down the query into manageable parts, tracking rankings and aggregations.
2. **ROW_NUMBER()** window function for ranking movies within their production year.
3. **STRING_AGG()** for concatenating keywords associated with movies.
4. **COALESCE** for handling NULL values in company names to provide a default value.
5. A **NULL logic check** to categorize actor counts and an **unusual WHERE clause** with a mix of conditions on multiple fields.

The query retrieves a list of movies from the year 2000 onward with complex filtering logic, allowing for performance benchmarking of various SQL features.
