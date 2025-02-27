WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY rand()) AS random_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
),
MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(STRING_AGG(DISTINCT a.name, ', '), 'Unknown') AS actors,
        COALESCE(STRING_AGG(DISTINCT c.name, ', '), 'No Companies') AS companies,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        MAX(mc.note) AS company_note
    FROM aka_title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword k ON t.id = k.movie_id
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actors,
        md.companies,
        md.keyword_count,
        CASE 
            WHEN md.keyword_count > 5 THEN 'Highly Tagged'
            WHEN md.keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
            ELSE 'Lightly Tagged'
        END AS tagging_level,
        DENSE_RANK() OVER (ORDER BY md.production_year DESC) AS release_rank
    FROM MovieDetails md
    WHERE md.companies <> 'No Companies'
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.actors,
        tm.companies,
        tm.tagging_level,
        tm.release_rank,
        EXISTS (SELECT 1 FROM CastRoles cr WHERE cr.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1) 
                 AND cr.role LIKE 'Director%') AS has_director
    FROM TopMovies tm
    WHERE tm.release_rank <= 10
)
SELECT 
    title,
    production_year,
    actors,
    companies,
    tagging_level,
    has_director
FROM FinalResults
WHERE production_year IS NOT NULL
ORDER BY production_year DESC, tagging_level ASC;

This SQL query utilizes various constructs and concepts including:

1. **Common Table Expressions (CTEs)** such as `RankedTitles`, `CastRoles`, `MovieDetails`, `TopMovies`, and `FinalResults` to structure the query logically and enable easier reading and maintenance.
2. **Window Functions** like `ROW_NUMBER()` and `DENSE_RANK()` to rank titles, cast roles, and control the order of results.
3. **Outer Joins** (LEFT JOIN) to ensure that we include movies even if there are no associated cast, companies, or keywords.
4. **STRING_AGG** to aggregate actor names and company names into a single string.
5. **NULL Logic** with `COALESCE` to handle potential NULL values in aggregations.
6. **Complicated Predicates** in the `CASE` statement to categorize movies based on keyword counts, and conditions in the `EXISTS` clause to check the presence of a director role.
7. **Calculations and Expressions** to derive movie release ranks and tagging levels.

This query is crafted to extract a rich dataset from the provided schema, while also showcasing many intricate SQL features.
