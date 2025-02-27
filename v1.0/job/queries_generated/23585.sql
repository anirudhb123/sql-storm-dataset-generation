WITH Recursive MovieGraph AS (
    SELECT 
        mt.title AS movie_title,
        c.name AS company_name,
        CASE 
            WHEN k.keyword IS NOT NULL THEN k.keyword 
            ELSE 'No keyword'
        END AS keyword,
        COUNT(DISTINCT ci.person_id) AS total_cast_count,
        COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.nr_order IS NOT NULL) AS ordered_cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS recent_rank
    FROM 
        aka_title mt 
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id 
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.production_year > 2000
    GROUP BY 
        mt.id, c.name, k.keyword
),
CombinedMovies AS (
    SELECT 
        mg.movie_title,
        mg.company_name,
        mg.keyword,
        mg.total_cast_count,
        mg.ordered_cast_count,
        mg.recent_rank,
        COALESCE(mg.recent_rank, 99) AS fallback_rank -- Handling NULL with COALESCE
    FROM 
        MovieGraph mg
    WHERE 
        mg.total_cast_count > 0
),
FinalResults AS (
    SELECT 
        cm.movie_title,
        cm.company_name,
        cm.keyword,
        cm.total_cast_count,
        cm.ordered_cast_count,
        (cm.total_cast_count * 1.0) / NULLIF(cm.ordered_cast_count, 0) AS cast_order_ratio, -- Prevent divide by zero
        ROW_NUMBER() OVER (ORDER BY cm.fallback_rank, cm.total_cast_count DESC) AS row_order
    FROM 
        CombinedMovies cm
    WHERE 
        cm.keyword NOT LIKE 'No keyword' -- Exclude movies with no keywords
)
SELECT 
    fr.movie_title,
    fr.company_name,
    fr.keyword,
    fr.total_cast_count,
    fr.ordered_cast_count,
    fr.cast_order_ratio,
    CASE 
        WHEN fr.cast_order_ratio IS NULL THEN 'Ratio undetermined'
        ELSE 'Ratio determined'
    END AS ratio_status
FROM 
    FinalResults fr
WHERE 
    fr.row_order <= 50
ORDER BY 
    fr.cast_order_ratio DESC, fr.total_cast_count DESC, fr.movie_title;
