WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS akas
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_title ak ON t.id = ak.movie_id
    GROUP BY t.id
), 
top_movies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM ranked_movies rm
    WHERE rm.production_year >= 2000
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    tm.rank, 
    COALESCE(ci.kind, 'N/A') AS company_type
FROM top_movies tm
LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN company_type ci ON mc.company_type_id = ci.id
WHERE tm.rank <= 10
ORDER BY tm.rank;
