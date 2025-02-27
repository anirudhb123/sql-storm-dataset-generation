WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        mc.note IS NULL
    GROUP BY 
        mc.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    fa.actor_name,
    fa.movie_count,
    mc.company_count,
    mc.company_names,
    mwk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredActors fa ON fa.movie_count > 5 AND rm.movie_id IN (SELECT movie_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MoviesWithKeywords mwk ON rm.movie_id = mwk.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, fa.movie_count DESC;

This SQL query:
1. **Uses Common Table Expressions (CTEs)** to compute values for ranked movies, filtered actors, movie companies, and movies with keywords.
2. **Employs window functions**, particularly `ROW_NUMBER()`, to rank movies by their production year.
3. **Filters actors** based on their number of movie appearances (>5).
4. **Aggregates company names** and counts associated with each movie that has no associated notes.
5. **Introduces a variety of joins** including left joins to retain movie records even if certain data points (like actor or company info) are missing.
6. **Ensures keyword information** is retrieved alongside other related data linked to specific movies.
7. **Maintains a condition to only show the top ten movies** based on their production year. 

This structure allows for complex aggregations, joins, and filtering while showcasing the relationships between movies, actors, companies, and keywords.
