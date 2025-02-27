WITH RecursiveCTE AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT ca.person_id) AS total_cast,
        SUM(CASE WHEN ca.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        cast_info ca
    JOIN 
        title t ON ca.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        c.movie_id
),
ExtendedCTE AS (
    SELECT 
        r.movie_id,
        r.total_cast,
        r.null_notes_count,
        (SELECT COUNT(*) 
         FROM movie_info mi
         WHERE mi.movie_id = r.movie_id AND mi.info_type_id = 1) AS info_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RecursiveCTE r
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        r.movie_id, r.total_cast, r.null_notes_count
),
FinalCTE AS (
    SELECT 
        e.movie_id,
        e.total_cast,
        e.null_notes_count,
        e.info_count,
        e.keywords,
        ROW_NUMBER() OVER (PARTITION BY e.info_count ORDER BY e.total_cast DESC) AS cast_rank
    FROM 
        ExtendedCTE e
)
SELECT 
    t.title,
    coalesce(cast_rank, 'No Rank') AS cast_rank,
    total_cast,
    COALESCE(keywords, 'No Keywords') AS keywords,
    (SELECT AVG(total_cast) FROM FinalCTE) AS avg_cast,
    CASE 
        WHEN total_cast > (SELECT AVG(total_cast) FROM FinalCTE) THEN 'Above Average'
        WHEN total_cast < (SELECT AVG(total_cast) FROM FinalCTE) THEN 'Below Average'
        ELSE 'Average'
    END AS cast_performance
FROM 
    FinalCTE f
JOIN 
    title t ON f.movie_id = t.id
WHERE 
    f.null_notes_count > 0 OR f.total_cast >= ALL (SELECT total_cast FROM ExtendedCTE)
ORDER BY 
    total_cast DESC NULLS LAST;

This SQL query contains:
- Common Table Expressions (CTEs) for better organization, recursive CTE for counting distinct cast members, and aggregating keyword data.
- Aggregate functions like COUNT, SUM, and STRING_AGG to provide insights into casting and movie info.
- Conditional logic using CASE statements to determine cast performance relative to average cast size.
- Outer joins with NULL logic to include movies with no keywords and only consider those with at least some null notes.
- Ordered results based on cast size while applying NULL handling.
