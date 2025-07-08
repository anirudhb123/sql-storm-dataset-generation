
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rank
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name m ON mc.company_id = m.id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM RankedMovies
    WHERE rank <= 5
),
CastRoles AS (
    SELECT 
        p.name,
        c.note,
        r.role,
        t.title,
        t.production_year
    FROM cast_info c
    JOIN aka_name p ON c.person_id = p.person_id
    JOIN role_type r ON c.role_id = r.id
    JOIN title t ON c.movie_id = t.id
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(DISTINCT cr.name) AS actor_count,
    LISTAGG(DISTINCT cr.role, ', ') WITHIN GROUP (ORDER BY cr.role) AS roles,
    CASE 
        WHEN COUNT(DISTINCT cr.name) > 5 THEN 'Ensemble Cast'
        ELSE 'Selective Cast'
    END AS cast_type
FROM TopMovies tm
LEFT JOIN CastRoles cr ON tm.title = cr.title AND tm.production_year = cr.production_year
GROUP BY tm.title, tm.production_year
ORDER BY tm.production_year DESC, actor_count DESC;
