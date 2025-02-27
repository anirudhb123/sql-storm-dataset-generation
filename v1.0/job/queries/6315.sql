WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title, 
        m.production_year,
        COALESCE(SUM(mk.keyword_id), 0) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE m.production_year >= 2000
    GROUP BY m.id, m.title, m.production_year
),
PopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC, cast_count DESC) AS rank
    FROM RankedMovies
)
SELECT 
    pm.title,
    pm.production_year,
    pm.keyword_count,
    pm.cast_count,
    p.name AS main_actor
FROM PopularMovies pm
JOIN cast_info ci ON pm.movie_id = ci.movie_id AND ci.nr_order = 1
JOIN aka_name p ON ci.person_id = p.person_id
WHERE pm.rank <= 10
ORDER BY pm.keyword_count DESC, pm.cast_count DESC;
