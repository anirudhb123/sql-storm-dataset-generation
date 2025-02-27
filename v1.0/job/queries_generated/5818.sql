WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM aka_title at
    JOIN cast_info c ON at.id = c.movie_id
    JOIN aka_name an ON c.person_id = an.person_id
    WHERE at.production_year >= 2000 AND at.kind_id = 1
    GROUP BY at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        actor_names,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.actor_names,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(mci.info_count, 0) AS company_info_count
FROM TopMovies tm
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(*) AS keyword_count 
    FROM movie_keyword 
    GROUP BY movie_id
) mk ON tm.movie_id = mk.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(*) AS info_count 
    FROM movie_info 
    GROUP BY movie_id
) mci ON tm.movie_id = mci.movie_id
WHERE tm.rank <= 10
ORDER BY tm.total_cast DESC;
