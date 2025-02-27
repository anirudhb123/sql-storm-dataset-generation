WITH Recursive_Cast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        c.role_id,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_order
    FROM 
        cast_info c
    WHERE 
        c.nr_order IS NOT NULL
),
Movie_Info_Aggregate AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS aggregated_info
    FROM 
        movie_info mi
    INNER JOIN 
        aka_title m ON mi.movie_id = m.movie_id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        m.movie_id
),
Keyword_Count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
Filtered_Movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COALESCE(kw.keyword_total, 0) AS keyword_count,
        coalesce(mia.aggregated_info, 'No additional information') AS additional_info
    FROM 
        aka_title a
    LEFT JOIN 
        Keyword_Count kw ON a.movie_id = kw.movie_id
    LEFT JOIN 
        Movie_Info_Aggregate mia ON a.movie_id = mia.movie_id
    WHERE 
        (a.production_year >= 2000 AND a.production_year <= 2023)
        AND (a.title IS NOT NULL AND LENGTH(a.title) > 0)
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keyword_count,
    f.additional_info,
    CAST(COALESCE(c.person_id, 0) AS INTEGER) AS lead_actor_id,
    MAX(CASE WHEN c.cast_order = 1 THEN c.person_id END) AS lead_actor
FROM 
    Filtered_Movies f
LEFT JOIN 
    Recursive_Cast c ON f.movie_id = c.movie_id
GROUP BY 
    f.movie_id, f.title, f.production_year, f.keyword_count, f.additional_info
ORDER BY 
    f.production_year DESC, f.title
LIMIT 100;


This query achieves several objectives:
1. It uses Common Table Expressions (CTEs) for modular querying.
2. Recursive_Cast collects and orders the cast information based on their role's order.
3. Movie_Info_Aggregate aggregates all additional information related to movies into a single string.
4. Keyword_Count counts the associated keywords for each movie.
5. Filtered_Movies forms a consolidated view of movies from 2000 to 2023 that also checks for non-empty titles.
6. The final SELECT consolidates the data by performing outer joins to gather lead actor information and filters out irrelevant results, while handling NULLs and ensuring that if there are no actors, a default integer value (0) is returned.

This exercise reflects efficient SQL practices through the use of aggregate functions and conditional logic while incorporating common corner cases & semantical quirks.
