WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        a.id AS title_id
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
CompanyCount AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM movie_companies mc
    JOIN movie_info mi ON mi.movie_id = mc.movie_id
    WHERE mi.info LIKE '%Blockbuster%'
    GROUP BY m.movie_id
),
TopRankedFilms AS (
    SELECT 
        rt.title,
        rt.production_year,
        cc.num_companies,
        RANK() OVER (ORDER BY rt.production_year DESC, cc.num_companies DESC) AS film_rank
    FROM RankedTitles rt
    LEFT JOIN CompanyCount cc ON rt.title_id = cc.movie_id
    WHERE rt.title_rank <= 5 OR cc.num_companies IS NULL
)
SELECT 
    trf.title,
    trf.production_year,
    COALESCE(tc.num_companies, 0) AS total_companies,
    CASE 
        WHEN tc.num_companies IS NOT NULL AND tc.num_companies > 3 
             THEN 'High Production'
        WHEN tc.num_companies IS NULL 
             THEN 'No Production Companies'
        ELSE 'Standard Production'
    END AS production_status
FROM TopRankedFilms trf
LEFT JOIN (
    SELECT DISTINCT movie_id, COUNT(company_id) OVER (PARTITION BY movie_id) AS num_companies
    FROM movie_companies
) tc ON trf.id = tc.movie_id
WHERE trf.film_rank <= 20
ORDER BY trf.production_year DESC, production_status;

### Breakdown of the Query:
- **CTEs Used**:
  - `RankedTitles`: Ranks titles by year and assigns a row number.
  - `CompanyCount`: Counts the number of unique companies for movies with the "Blockbuster" keyword in their info.
  - `TopRankedFilms`: Combines the previous two CTEs, ranking films based on year and number of production companies.

- **Filtering Logic**:
  - Filters titles based on rank and includes NULL checks to handle cases without associated companies.

- **Window Functions**: 
  - Utilizes `ROW_NUMBER()` and `RANK()` to manage rankings dynamically within subsets of data.

- **Conditional Logic**:
  - Utilizes `CASE` statements to assign production status based on the count of associated companies. 

- **Outer Joins**: 
  - `LEFT JOIN` used to incorporate counts of companies that may not exist for certain titles.

- **Complex Predicates**: 
  - Uses predicates to create a diverse output based on business logic such as production status.

This query is structured to test performance by using various features of SQL that can create complex behavior while still maintaining clarity on intentions and results.
