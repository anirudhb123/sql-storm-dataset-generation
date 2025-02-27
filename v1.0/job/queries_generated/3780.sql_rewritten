WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank_per_year
    FROM title
    WHERE title.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.nr_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    COUNT(DISTINCT mc.actor_name) AS num_actors,
    STRING_AGG(DISTINCT cd.company_name, ', ') AS companies_involved,
    mi.movie_info,
    MAX(CASE WHEN mc.role_name IS NULL THEN 'Unknown' ELSE mc.role_name END) AS prominent_role
FROM RankedMovies rm
LEFT JOIN MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE rm.rank_per_year <= 5 
GROUP BY rm.movie_title, rm.production_year, mi.movie_info
ORDER BY rm.production_year DESC, num_actors DESC;