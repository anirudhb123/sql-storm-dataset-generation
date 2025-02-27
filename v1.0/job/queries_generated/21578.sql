WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY m.title) AS rn,
        COUNT(*) OVER(PARTITION BY m.production_year) AS total_movies
    FROM title m
    WHERE m.production_year IS NOT NULL
), 
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rn,
        rm.total_movies
    FROM RankedMovies rm
    WHERE rm.rn <= 5
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        GROUP_CONCAT(mi.info) AS infos
    FROM movie_info mi
    GROUP BY mi.movie_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')') ORDER BY a.name) AS actors
    FROM cast_info c
    JOIN aka_name a ON a.person_id = c.person_id
    JOIN role_type rt ON rt.id = c.role_id
    GROUP BY c.movie_id
),
MovieFactory AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        mf.company_id,
        cn.name AS company_name,
        c.actor_count,
        c.actors,
        COALESCE(mv.infos, 'No Info') AS additional_info
    FROM TopRankedMovies tm
    LEFT JOIN movie_companies mf ON tm.movie_id = mf.movie_id
    LEFT JOIN company_name cn ON cn.id = mf.company_id
    LEFT JOIN CastDetails c ON c.movie_id = tm.movie_id
    LEFT JOIN MovieInfo mv ON mv.movie_id = tm.movie_id
)
SELECT 
    mf.title,
    mf.production_year,
    mf.company_name,
    mf.actor_count,
    mf.actors,
    CASE 
        WHEN mf.actor_count IS NULL THEN 'No Cast'
        WHEN mf.actor_count > 0 THEN 'Has Cast'
        ELSE 'Unknown'
    END AS cast_status,
    COALESCE(mf.additional_info, 'No additional info available') AS additional_info
FROM MovieFactory mf
WHERE (mf.company_name IS NOT NULL OR mf.actor_count > 0)
ORDER BY mf.production_year DESC, mf.title ASC;
