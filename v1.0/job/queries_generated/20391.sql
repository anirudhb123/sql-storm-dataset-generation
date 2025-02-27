WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(
            (SELECT GROUP_CONCAT(a.name ORDER BY c.nr_order SEPARATOR ', ') 
             FROM cast_info c 
             JOIN aka_name a ON c.person_id = a.person_id 
             WHERE c.movie_id = t.id),
            'No Cast') AS cast_list,
        (SELECT COUNT(DISTINCT mc.company_id) 
         FROM movie_companies mc 
         WHERE mc.movie_id = t.id) AS company_count
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv_movie'))
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_list,
        company_count,
        ROW_NUMBER() OVER(PARTITION BY production_year ORDER BY company_count DESC, title) AS rn
    FROM 
        MovieDetails
),
RankedMovies AS (
    SELECT 
        *,
        CASE 
            WHEN company_count = 0 THEN 'Unknown Company'
            ELSE 'Known Company'
        END AS company_status
    FROM 
        FilteredMovies
    WHERE 
        rn <= 5
    ORDER BY 
        production_year DESC
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_list,
    rm.company_count,
    rm.company_status,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(rm.production_year AS text) || ' was an interesting year!'
    END AS year_comment,
    COALESCE(
        (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = rm.movie_id),
        'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
WHERE 
    (mi.info IS NOT NULL OR rm.company_status = 'Unknown Company')
ORDER BY 
    rm.production_year DESC, 
    rm.company_count DESC;

This complex query demonstrates several SQL features:

- **Common Table Expressions (CTEs)**: `MovieDetails`, `FilteredMovies`, and `RankedMovies` are used to break down the logic into manageable components.
- **Subqueries**: Used to aggregate information such as casting and company counts, including a correlated subquery.
- **Window Functions**: `ROW_NUMBER()` assigns a ranking based on the count of companies per production year.
- **String Expressions**: The `string_agg` function concatenates keywords, demonstrating aggregate string processing.
- **NULL logic and predicates**: `COALESCE` is used to handle NULL scenarios elegantly, providing defaults for missing data.
- **CASE statements**: Implemented for conditional logic evaluation in the output columns.
- **Outer Join**: A left join with `movie_info` helps in including movies even if they lack info tagged as 'tagline'.

This structure offers not only a demonstration of SQL capabilities but also provides insights into movie production data filtered for further analysis.
