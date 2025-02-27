WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(array_agg(DISTINCT c.name) FILTER (WHERE c.name IS NOT NULL), '{}') AS cast_names,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS role_order
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON c.movie_id = m.id
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        m.id
),
MovieKeywordCTE AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
CompanyInfoCTE AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY mc.note) AS company_order
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON c.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
)

SELECT 
    m.title,
    m.production_year,
    m.cast_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(ci.company_name, 'Independent') AS production_company,
    ci.company_type AS company_type,
    ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS movie_rank
FROM 
    RecursiveMovieCTE m
LEFT JOIN 
    MovieKeywordCTE mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    CompanyInfoCTE ci ON ci.movie_id = m.movie_id AND ci.company_order = 1
WHERE 
    m.production_year >= 2000
    AND m.cast_names IS NOT NULL
    AND m.title NOT LIKE '%Untitled%'
ORDER BY 
    m.production_year DESC, 
    movie_rank;

### Explanation:
1. **Common Table Expressions (CTEs)**: 
   - `RecursiveMovieCTE` collects movie titles, production years, and casts while maintaining the order of roles.
   - `MovieKeywordCTE` gathers keywords associated with movies.
   - `CompanyInfoCTE` retrieves information about production companies, limiting the results to the top-ranked company per movie.

2. **Conditional Aggregation**: 
   - `COALESCE` is used to manage NULLs, providing default values when no data exists (e.g., 'No Keywords', 'Independent').

3. **Window Functions**: 
   - `ROW_NUMBER()` is applied to organize cast names and rank movies by production year.

4. **Advanced Filtering**: 
   - The main query applies stringent filtering conditions, ensuring only movies from 2000 onward, excluding untitled works and retaining movies with known casts get selected.

5. **String Aggregation**: 
   - The `STRING_AGG` function is used to concatenate keyword strings into a single entry for each movie.

This elaborate query showcases an intricate use of SQL's capabilities, featuring various elements such as outer joins, subqueries, window functions, and complex predicates.

