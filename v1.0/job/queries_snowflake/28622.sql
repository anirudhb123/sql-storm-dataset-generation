
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),

MajorProductionCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
    HAVING COUNT(*) > 1
),

TopMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.cast_count,
        mpc.company_name,
        mpc.company_type
    FROM RankedTitles rt
    JOIN MajorProductionCompanies mpc ON rt.title_id = mpc.movie_id
    ORDER BY rt.cast_count DESC, rt.production_year DESC
    LIMIT 10
)

SELECT 
    t.title,
    t.production_year,
    t.cast_count,
    t.company_name,
    t.company_type
FROM TopMovies t;
