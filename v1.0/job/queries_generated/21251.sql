WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast,
        MAX(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) as has_roles
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        *,
        CASE 
            WHEN rank_by_cast <= 5 THEN 'Top 5'
            WHEN rank_by_cast <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS cast_category
    FROM 
        ranked_movies
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ct.kind) FILTER (WHERE ct.kind ILIKE '%Production%') AS production_company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        cs.company_count,
        cs.production_company_count,
        tm.cast_category,
        tm.has_roles
    FROM 
        top_movies tm
    LEFT JOIN 
        company_stats cs ON tm.movie_id = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_count, 0) AS total_companies,
    COALESCE(md.production_company_count, 0) AS production_companies,
    md.cast_category,
    md.has_roles,
    CASE 
        WHEN md.has_roles = 1 THEN 'Has Roles' 
        ELSE 'No Roles' 
    END AS role_description
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
    AND md.cast_category != 'Other'
ORDER BY 
    md.production_year DESC, md.total_companies DESC
LIMIT 100;


This query breaks down as follows:

1. **CTEs**:
   - `ranked_movies`: This CTE ranks movies by the count of their cast members per production year. It includes a conditional check to flag whether there are roles associated with the cast members.
   - `top_movies`: Categorizes the movies based on their cast rank into 'Top 5', 'Top 10', and 'Other'.
   - `company_stats`: Aggregates the total number of unique companies that worked on each movie while counting only those categorized as production companies.

2. **Final selection**: 
   - Joins the `top_movies` and `company_stats` CTEs to get comprehensive movie details.
   - Filters for movies from 2000 onward and that are part of the 'Top 5' or 'Top 10'.
   - Includes `COALESCE` for handling `NULL` values elegantly.
   - Uses a case statement to provide human-readable descriptors for roles.

3. **Complex conditions and window functions**, like ROW_NUMBER and aggregate functions, illustrate advanced SQL constructs suitable for performance benchmarking in a database environment.
