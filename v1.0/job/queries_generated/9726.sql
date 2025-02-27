WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ci.person_role_id,
        a.name AS actor_name,
        c.kind AS role_name,
        COUNT(mi.id) AS info_count
    FROM RankedMovies rm
    JOIN complete_cast cc ON rm.movie_id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type c ON ci.role_id = c.id
    LEFT JOIN movie_info mi ON rm.movie_id = mi.movie_id
    GROUP BY rm.movie_id, rm.title, rm.production_year, ci.person_role_id, a.name, c.kind
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.role_name,
    md.info_count
FROM MovieDetails md
WHERE md.year_rank <= 5
ORDER BY md.production_year DESC, md.title ASC;
