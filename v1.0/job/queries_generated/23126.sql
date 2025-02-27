WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.company_count
    FROM RankedMovies rm
    WHERE rm.rank <= 5
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
MoviesWithRoles AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        cr.role,
        COALESCE(cr.role_count, 0) AS role_count
    FROM TopMovies tm
    LEFT JOIN CastRoles cr ON tm.title_id = cr.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.role,
    mw.role_count,
    CASE
        WHEN mw.role_count > 5 THEN 'Popular Role'
        WHEN mw.role_count = 0 THEN 'No Roles'
        ELSE 'Moderate Role'
    END AS role_category,
    COALESCE(ai.total_awards, 0) AS total_awards,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM MoviesWithRoles mw
LEFT JOIN (
    SELECT 
        m.movie_id,
        COUNT(ai.id) AS total_awards
    FROM (SELECT DISTINCT movie_id FROM complete_cast) m
    LEFT JOIN (SELECT movie_id, id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'awards')) ai ON m.movie_id = ai.movie_id
    GROUP BY m.movie_id
) ai ON mw.title_id = ai.movie_id
LEFT JOIN movie_keyword mk ON mw.title_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
GROUP BY mw.title_id, mw.title, mw.production_year, mw.role, mw.role_count, ai.total_awards
ORDER BY mw.production_year DESC, mw.role_count DESC;

