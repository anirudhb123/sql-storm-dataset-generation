
WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS has_rating,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 2 THEN 1 ELSE 0 END), 0) AS has_reviews
    FROM title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    WHERE m.production_year >= 2000
    GROUP BY m.title, m.production_year
),
TopMovies AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM RankedMovies
)
SELECT 
    tm.title AS movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    CASE
        WHEN tm.has_rating > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_rating,
    CASE
        WHEN tm.has_reviews > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_reviews
FROM TopMovies tm
WHERE tm.rank <= 10
ORDER BY tm.total_cast DESC;
