WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as rn,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY a.id) as cast_count
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    WHERE a.production_year IS NOT NULL
      AND a.title NOT LIKE '%[Aa]berration%'  -- Exclude titles with specific patterns
      AND k.keyword IS NOT NULL
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(MAX(cast_count), 0) AS total_cast_count,
    STRING_AGG(DISTINCT rm.keyword, ', ') AS keywords_used,
    CASE 
        WHEN total_cast_count > 10 THEN 'Large Ensemble'
        WHEN total_cast_count BETWEEN 5 AND 10 THEN 'Medium Ensemble'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM RankedMovies rm
LEFT JOIN (SELECT movie_id, COUNT(DISTINCT person_id) as cast_count 
            FROM cast_info 
            WHERE person_role_id IS NULL
            GROUP BY movie_id) AS role_summary 
ON rm.id = role_summary.movie_id
WHERE rm.rn <= 10 -- Selecting only the top 10 recent movies per year
GROUP BY rm.title, rm.production_year
HAVING COUNT(DISTINCT rm.keyword) > 2 -- Only showing titles with more than 2 distinct keywords
ORDER BY rm.production_year DESC, total_cast_count DESC
LIMIT 50;

### Explanation:
- **Common Table Expression (CTE)**: The `RankedMovies` CTE is created first to rank movies by production year and count distinct cast members per movie, filtering out titles containing 'Aberration' and ensuring a keyword is present.
- **Window Functions**: `ROW_NUMBER()` is used to rank movies within each production year, while `COUNT(DISTINCT ci.person_id)` counts unique cast members for each movie.
- **Outer Joins**: The CTE utilizes several `LEFT JOIN`s to connect `aka_title`, `movie_keyword`, and `cast_info` on relevant identifiers, allowing for NULL values to be retained.
- **Conditional Logic**: The algorithm categorizes cast size based on the number of unique cast members.
- **String Aggregation**: `STRING_AGG()` collects distinct keywords for each movie, presenting them as a comma-separated string.
- **Predicate Logic**: The `HAVING` clause filters results to include only movies with more than two keywords, maintaining quality results.
- **Complexity**: The SQL query is intricate, featuring advanced constructs like CTEs, window functions, outer joins, string aggregation, and complex conditional logic that highlights unusual and obscure SQL semantics, making it suitable for performance benchmarking within this schema.
