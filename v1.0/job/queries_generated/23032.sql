WITH RankedTitles AS (
    SELECT t.id,
           t.title,
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
CompanyMovieInfo AS (
    SELECT m.movie_id,
           c.name AS company_name,
           ct.kind AS company_type,
           COUNT(*) AS total_movies
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY m.movie_id, c.name, ct.kind
),
ActorRoles AS (
    SELECT a.person_id,
           COUNT(DISTINCT ci.movie_id) AS movies_played,
           STRING_AGG(DISTINCT r.role || ' in ' || t.title, '; ') AS roles
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.id
    JOIN title t ON ci.movie_id = t.id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY a.person_id
)
SELECT rt.production_year,
       rt.title,
       rt.year_rank,
       crm.company_name,
       crm.company_type,
       ar.movies_played,
       ar.roles
FROM RankedTitles rt
LEFT JOIN CompanyMovieInfo crm ON rt.id = crm.movie_id
LEFT JOIN ActorRoles ar ON rt.id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.movie_id = rt.id)
WHERE rt.year_rank <= 5
  AND crm.total_movies > 1
ORDER BY rt.production_year DESC, rt.title
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

### Explanation:
- **CTEs (Common Table Expressions)**: Three CTEs are used here (`RankedTitles`, `CompanyMovieInfo`, and `ActorRoles`) to handle complex aggregations, rankings, and join operations.
- **Ranking Function**: `ROW_NUMBER()` is utilized to rank titles per year, allowing for interesting filtering later in the main query.
- **String Aggregation**: `STRING_AGG()` provides a comma-separated string of roles that an actor has played in different movies, thus capturing multiple values in a single column.
- **Outer Join**: A `LEFT JOIN` is used to include all titles regardless of if they have company associations or actor roles.
- **Correlated Subquery**: The use of `IN` in the `JOIN` from `ActorRoles` to retrieve movies related to actors ensures filtering can be done in a granular manner.
- **Complicated Filtering**: Several predicates ensure the results are relevant, including ranking filtering and checking the count of movies produced by companies.
- **Pagination**: `OFFSET` and `FETCH NEXT` provides a way to paginate the results, an unusual yet powerful feature allowing segmented output.
- **NULL Logic**: The outer joins effectively handle cases where there may be no associated companies or actors for some titles, preserving title information while showing NULLs for missing data.
- **Unusual Semantics**: Requiring only companies linked to more than one movie and limiting to top 5 per year add unexpected complexity often underused in queries.
