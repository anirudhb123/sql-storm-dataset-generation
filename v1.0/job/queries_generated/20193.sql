WITH TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank,
        COUNT(k.id) OVER(PARTITION BY t.id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
      AND (k.keyword IS NOT NULL OR t.title LIKE '%Star%')
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        string_agg(DISTINCT mi.info, '; ') AS info_details
    FROM movie_info mi
    GROUP BY mi.movie_id
),
TopMovies AS (
    SELECT 
        td.title_id,
        td.title,
        td.production_year,
        td.keyword,
        td.keyword_rank,
        mi.info_details,
        COALESCE(b.cast_count, 0) AS total_cast,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = td.title_id) AS company_count,
        NTILE(5) OVER(ORDER BY td.production_year DESC) AS decade_rank
    FROM TitleDetails td
    LEFT JOIN (
        SELECT 
            movie_id, COUNT(*) AS cast_count
        FROM cast_info
        GROUP BY movie_id
    ) b ON td.title_id = b.movie_id
    LEFT JOIN MovieInfo mi ON td.title_id = mi.movie_id
    WHERE (td.keyword_rank <= 3 OR td.keyword_count > 5)
      AND (td.production_year BETWEEN 1990 AND 2020)
)
SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.info_details,
    tm.total_cast,
    tm.company_count,
    tm.decade_rank
FROM TopMovies tm
WHERE tm.total_cast > 1
  AND (tm.company_count IS NULL OR tm.company_count > 0)
ORDER BY tm.production_year DESC, tm.total_cast DESC;

