WITH RankedMovies AS (
    SELECT 
        mv.id AS movie_id,
        mv.title,
        mv.production_year,
        ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY mv.title) AS rank
    FROM title mv
    WHERE mv.production_year IS NOT NULL
),
CompanyFilms AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.movie_id
),
RoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_actors
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cf.company_count, 0) AS company_count,
        COALESCE(rc.actor_count, 0) AS actor_count,
        COALESCE(rc.ordered_actors, 0) AS ordered_actors
    FROM RankedMovies rm
    LEFT JOIN CompanyFilms cf ON rm.movie_id = cf.movie_id
    LEFT JOIN RoleCounts rc ON rm.movie_id = rc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.actor_count,
    md.ordered_actors,
    CASE 
        WHEN md.company_count > 0 AND md.actor_count > 0 THEN 'Both Companies and Actors Present'
        WHEN md.company_count > 0 THEN 'Only Companies Present'
        WHEN md.actor_count > 0 THEN 'Only Actors Present'
        ELSE 'No Companies or Actors'
    END AS presence_summary
FROM MovieDetails md
WHERE md.production_year BETWEEN 2000 AND 2020
ORDER BY md.production_year DESC, md.title ASC;
