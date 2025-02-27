WITH RecursiveMovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(r.rank) AS average_rank,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        (SELECT COUNT(DISTINCT mc.company_id) 
         FROM movie_companies mc 
         WHERE mc.movie_id = t.id) AS company_count
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            DENSE_RANK() OVER (PARTITION BY movie_id ORDER BY kind_id) AS rank
        FROM aka_title 
        WHERE production_year > 2000
    ) r ON t.id = r.movie_id
    LEFT JOIN movie_keyword k ON t.id = k.movie_id
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.average_rank,
        ms.keyword_count,
        ms.company_count,
        ROW_NUMBER() OVER (ORDER BY ms.total_cast DESC, ms.average_rank ASC) AS rank
    FROM RecursiveMovieStats ms
    WHERE ms.total_cast > 5 AND ms.company_count > 2
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.average_rank,
    tm.keyword_count,
    CASE 
        WHEN tm.average_rank IS NULL THEN 'No Rank Available' 
        ELSE CAST(tm.average_rank AS TEXT) 
    END AS formatted_rank,
    COALESCE(cn.name, 'Unknown Company') AS company_name
FROM TopMovies tm
LEFT JOIN (
    SELECT 
        mc.movie_id, 
        cn.name
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id, cn.name
    HAVING COUNT(*) > 1
) AS company_details ON tm.movie_id = company_details.movie_id
LEFT JOIN movie_info mi ON tm.movie_id = mi.movie_id 
WHERE mi.info_type_id IS NULL OR mi.info LIKE '%Award%'
  OR EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = tm.movie_id AND cc.status_id IS NOT NULL)
ORDER BY tm.rank
FETCH FIRST 10 ROWS ONLY;
This SQL query performs a variety of operations including utilizing Common Table Expressions (CTEs), aggregate functions, window functions, correlated subqueries, outer joins, and conditional logic with `CASE` and `COALESCE`. It filters and ranks movies based on cast count and company participation while adapting to edge cases like handling NULLs and ensuring sufficient cast members and companies are present, creating a comprehensive overview of notable movies.
