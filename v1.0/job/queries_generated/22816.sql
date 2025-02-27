WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS movie_rank
    FROM aka_title AS mt
    LEFT JOIN cast_info AS cc ON mt.movie_id = cc.movie_id
    LEFT JOIN aka_name AS ak ON cc.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
    GROUP BY mt.title, mt.production_year
),

FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.actor_names
    FROM RankedMovies AS rm
    WHERE rm.movie_rank <= 3
),

CompanyMovieDetails AS (
    SELECT 
        mt.movie_id,
        c.name AS company_name,
        ct.kind AS company_kind,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_companies AS mc
    JOIN company_name AS c ON mc.company_id = c.id
    JOIN company_type AS ct ON mc.company_type_id = ct.id
    JOIN movie_info AS mi ON mc.movie_id = mi.movie_id
    GROUP BY mt.movie_id, c.name, ct.kind
)

SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.actor_names,
    COALESCE(cmd.company_name, 'Unknown Company') AS company_name,
    COALESCE(cmd.company_kind, 'Unspecified Type') AS company_kind,
    cmd.info_type_count
FROM FilteredMovies AS fm
LEFT JOIN CompanyMovieDetails AS cmd ON fm.production_year = cmd.movie_id
WHERE fm.production_year IS NOT NULL
ORDER BY fm.production_year DESC, fm.total_cast DESC;

### Explanation:
- **Common Table Expressions (CTEs)**: 
  - `RankedMovies`: Aggregates movies, counting distinct cast members and ranking them by their total cast size within each production year.
  - `FilteredMovies`: Filters the top 3 movies per production year based on the total count of distinct cast members.
  - `CompanyMovieDetails`: Gathers company details associated with movies, counting the types of information linked to each movie.
  
- **SELECT Statement**: Combines the top movies with company data, with `COALESCE` used to handle NULLs for company names and types, assigning default values when no data exists.

- **Joins**: Both outer joins and inner joins are employed to ensure that we include all relevant movies even when company data may be absent.

- **ORDER BY**: Orders the final result set by production year, most recent first, and the count of cast members in descending order.

This query intricately employs various SQL constructs while carefully balancing complexity and performance benchmarking through aggregation and filtering.
