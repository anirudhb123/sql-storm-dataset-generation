WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword_count,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC, keyword_count DESC) AS ranking
    FROM RankedMovies
    WHERE production_year >= 2000
)
SELECT 
    fm.title,
    fm.production_year,
    fm.keyword_count,
    fm.cast_count,
    ak.name AS actor_name,
    rt.role AS role_type
FROM FilteredMovies fm
JOIN cast_info ci ON fm.title_id = ci.movie_id
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN role_type rt ON ci.person_role_id = rt.id
WHERE fm.ranking <= 10
ORDER BY fm.production_year DESC, fm.cast_count DESC;
