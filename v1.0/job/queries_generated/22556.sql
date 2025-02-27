WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
MovieCastInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(a.name, ', ') AS actors
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN RankedMovies m ON c.movie_id = m.movie_id
    GROUP BY m.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    m.movie_id,
    COALESCE(m.title, 'Unknown Title') AS title,
    COALESCE(m.production_year::TEXT, 'Year Unknown') AS production_year,
    COALESCE(ci.actor_count, 0) AS total_actors,
    COALESCE(ci.actors, 'No Actors') AS actors_list,
    COALESCE(cd.company_name, 'Independent') AS company_name,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    COALESCE(kw.keywords, 'No Keywords') AS keywords
FROM RankedMovies m
LEFT JOIN MovieCastInfo ci ON m.movie_id = ci.movie_id
LEFT JOIN CompanyDetails cd ON m.movie_id = cd.movie_id AND cd.company_rank = 1
LEFT JOIN MovieKeywords kw ON m.movie_id = kw.movie_id
WHERE m.rank <= 10
ORDER BY m.production_year DESC, m.movie_id;

This query performs the following actions:
1. **Common Table Expressions (CTEs)**: 
   - `RankedMovies` identifies the top 10 latest movies by type.
   - `MovieCastInfo` counts distinct actors and aggregates their names for each movie.
   - `CompanyDetails` gathers company information related to movies, ordering by company name.
   - `MovieKeywords` aggregates keywords associated with each movie.

2. **Main Query**: It combines information from the CTEs and the main movie table while applying various `COALESCE` functions to handle potential NULL values, providing default messages where necessary. 

3. **Joining and Filtering**: The outer joins ensure that all movies from the `RankedMovies` are returned even if they have no associated actors, companies, or keywords. The `WHERE` clause limits results to the top 10 movies based on their rank.

4. **Ordering the Results**: The results are ordered by `production_year` and `movie_id` to maintain a structured presentation.

5. **Use of Group Functions and Window Functions**: It effectively demonstrates the use of aggregate functions, string operations, and window functions to enrich the dataset for analysis.
