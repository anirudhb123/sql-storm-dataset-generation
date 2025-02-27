WITH
    RankedMovies AS (
        SELECT
            t.id AS movie_id,
            t.title,
            t.production_year,
            ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
            COUNT(ci.id) OVER (PARTITION BY t.id) AS cast_count
        FROM
            aka_title t
        LEFT JOIN
            movie_info mi ON t.id = mi.movie_id
        WHERE
            mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genres') 
            AND mi.info IS NOT NULL
    ),
    ActorRoles AS (
        SELECT
            c.movie_id,
            a.name AS actor_name,
            r.role AS role_name
        FROM
            cast_info c
        INNER JOIN
            aka_name a ON c.person_id = a.person_id
        INNER JOIN
            role_type r ON c.role_id = r.id
        WHERE
            r.role IS NOT NULL
    ),
    ComedyMovies AS (
        SELECT
            rm.movie_id,
            rm.title,
            rm.production_year,
            rm.cast_count,
            COALESCE(STRING_AGG(DISTINCT ar.actor_name, ', '), 'No Cast') AS cast_names
        FROM
            RankedMovies rm
        LEFT JOIN
            ActorRoles ar ON rm.movie_id = ar.movie_id
        WHERE
            rm.year_rank <= 3 AND rm.cast_count > 5
        GROUP BY
            rm.movie_id, rm.title, rm.production_year, rm.cast_count
    ),
    CompanyInfo AS (
        SELECT
            mc.movie_id,
            cn.name AS company_name,
            ct.kind AS company_type,
            COALESCE(COUNT(mc.company_id), 0) AS company_count
        FROM
            movie_companies mc
        LEFT JOIN
            company_name cn ON mc.company_id = cn.id
        LEFT JOIN
            company_type ct ON mc.company_type_id = ct.id
        GROUP BY
            mc.movie_id, cn.name, ct.kind
    )
SELECT
    cm.title,
    cm.production_year,
    cm.cast_count,
    cm.cast_names,
    ci.company_name,
    ci.company_type,
    ci.company_count
FROM
    ComedyMovies cm
LEFT JOIN
    CompanyInfo ci ON cm.movie_id = ci.movie_id
WHERE
    (cm.cast_count IS NOT NULL AND ci.company_count > 0) 
    OR (cm.cast_count IS NULL AND ci.company_count IS NULL)
ORDER BY
    cm.production_year DESC, cm.cast_count DESC NULLS LAST;

