WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
movie_companies_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name || ' (' || ct.kind || ')', ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_selection AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mci.companies,
        COALESCE(kc.keyword_total, 0) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, keyword_count DESC) AS overall_rank
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_companies_info mci ON rm.movie_id = mci.movie_id
    LEFT JOIN 
        keyword_count kc ON rm.movie_id = kc.movie_id
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.companies,
    f.keyword_count
FROM 
    final_selection f
WHERE 
    f.overall_rank <= 10
ORDER BY 
    f.production_year DESC, f.keyword_count DESC;

This SQL query generates a list of the top 10 movies ranked by production year and the number of associated keywords. It uses several interesting constructs:

- **Common Table Expressions (CTEs)**, like `ranked_movies`, `movie_companies_info`, and `keyword_count`, to add layers of calculation.
- **Window Functions**, to rank movies by cast size and overall rank.
- **LEFT JOINs** to ensure inclusion of all movies even if they lack associated data (like companies or keywords).
- **STRING_AGG** function to concatenate company names with their types.
- A **COALESCE** to handle potential NULL values in the keyword counts.
- **ORDER BY clauses** to sort results both within the CTEs and in the final selection.

This structure encapsulates multiple SQL constructs, showcases performance benchmarking potential in query execution, and demonstrates the ability to handle NULL scenarios and different aggregations.
