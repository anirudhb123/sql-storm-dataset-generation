WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
RecentMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        DENSE_RANK() OVER (ORDER BY rt.production_year DESC) AS recent_rank
    FROM RankedTitles rt
    WHERE rt.production_year >= (SELECT MAX(production_year) - 5 FROM title)
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.cast_count,
    cd.actor_names,
    mk.keyword_count,
    co.company_count,
    co.company_names,
    CASE 
        WHEN rt.recent_rank <= 3 THEN 'Recent Blockbuster'
        ELSE 'Classic'
    END AS movie_category
FROM RecentMovies rt
LEFT JOIN CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN MovieKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN CompanyDetails co ON rt.title_id = co.movie_id
WHERE (cd.cast_count IS NULL OR cd.cast_count > 0)
AND (mk.keyword_count IS NULL OR mk.keyword_count > 1)
ORDER BY rt.production_year DESC, cd.cast_count DESC;

This query performs the following operations:
1. It defines several Common Table Expressions (CTEs):
   - `RankedTitles`: Ranks titles based on production year and title while filtering out those with NULL production years.
   - `RecentMovies`: Fetches titles from the last five years and ranks them in descending order.
   - `CastDetails`: Aggregates actor names and counts for each movie.
   - `MovieKeywords`: Counts distinct keywords associated with each movie.
   - `CompanyDetails`: Counts and aggregates companies associated with each movie.
   
2. It combines these CTEs in the final `SELECT` statement, allowing for a comprehensive view of the recent titles, their cast, keywords, and production companies.

3. It applies conditions to filter the results based on presence or absence of cast and keyword counts, managing NULLs with logical ORs.

4. Finally, it categorizes movies into 'Recent Blockbuster' and 'Classic' based on their rankings and orders the results for clarity.
