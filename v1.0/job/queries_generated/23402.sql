WITH RECURSIVE title_hierarchy AS (
    SELECT 
        ct.id AS company_type_id,
        ct.kind AS company_kind,
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) as total_companies
    FROM 
        movie_companies mc 
    JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    GROUP BY 
        ct.id, ct.kind, mc.movie_id
),
ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) as title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_performance AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) as total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) as with_notes
    FROM 
        cast_info ci 
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
full_movie_data AS (
    SELECT 
        t.id AS movie_id,
        coalesce(title_h.company_kind, 'Unknown') as company_kind,
        rt.title,
        rt.production_year,
        cp.total_cast,
        cp.with_notes,
        mk.keywords
    FROM 
        ranked_titles rt
    LEFT JOIN 
        title_hierarchy title_h ON rt.title_id = title_h.movie_id
    LEFT JOIN 
        cast_performance cp ON rt.title_id = cp.movie_id
    LEFT JOIN 
        movie_keywords mk ON rt.title_id = mk.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.company_kind,
    f.total_cast,
    f.with_notes,
    f.keywords,
    (
        SELECT 
            COUNT(*) 
        FROM 
            aka_title ak 
        WHERE 
            ak.title = f.title AND ak.production_year = f.production_year
    ) AS aka_count,
    (
        SELECT 
            AVG(w.title_rank) 
        FROM 
            (
                SELECT 
                    RANK() OVER (ORDER BY title) AS title_rank 
                FROM 
                    ranked_titles
            ) w
    ) AS avg_title_rank
FROM 
    full_movie_data f
WHERE 
    f.with_notes > 0 
    AND f.total_cast > 1
ORDER BY 
    f.production_year DESC, 
    f.title ASC;

This SQL query includes multiple advanced constructs:

1. **Common Table Expressions (CTEs)** for organizing the data into logical layers, such as `title_hierarchy`, `ranked_titles`, `cast_performance`, and `movie_keywords`.
2. **Correlated subqueries** to count "aliases" in the `aka_title` table and calculate the average title rank.
3. **Window functions** (e.g., RANK) to rank titles within each production year and use this for additional calculations.
4. **NULL handling** using `COALESCE` for fallback values.
5. Various predicates to filter out results based on cast presence and company type.
6. **String aggregation** to compile keywords for titles.

The query showcases complex SQL techniques tailored for analyzing and summarizing a movie database with sophisticated predicates and calculations.
