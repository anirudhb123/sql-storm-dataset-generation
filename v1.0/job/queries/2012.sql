WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
RecentMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.cast_count
    FROM RankedMovies rm
    WHERE rm.rn <= 5
),
CastDetails AS (
    SELECT
        a.name AS actor_name,
        c.movie_id,
        c.nr_order,
        r.role AS role_name
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword_count,
    rm.cast_count,
    COALESCE(cd.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(cd.role_name, 'Unknown Role') AS role_name
FROM RecentMovies rm
LEFT JOIN CastDetails cd ON rm.movie_id = cd.movie_id
WHERE rm.keyword_count > 0
ORDER BY rm.production_year DESC, rm.cast_count DESC, rm.title;
