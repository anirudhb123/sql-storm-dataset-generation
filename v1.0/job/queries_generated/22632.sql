WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ca.movie_id,
        ka.name AS actor_name,
        COUNT(*) OVER (PARTITION BY ca.movie_id) AS actor_count,
        MAX(ka.name) OVER (PARTITION BY ca.movie_id) AS main_actor
    FROM 
        cast_info ca
    JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    WHERE 
        ka.name IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        mc.note AS company_note
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CompleteMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(am.actor_count, 0) AS actor_count,
        am.main_actor,
        COALESCE(SUM(CASE WHEN i.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS awards_count,
        COALESCE(cn.company_count, 0) AS company_count,
        COALESCE(CASE WHEN rm.total_movies > 0 THEN CONCAT(CAST(rm.title_rank AS VARCHAR), '/', CAST(rm.total_movies AS VARCHAR)) END, 'N/A') AS rank_over_total,
        CASE 
            WHEN SUM(i.info_type_id) IS NULL THEN 'No Info'
            ELSE 'Information Exists'
        END AS info_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
    LEFT JOIN 
        CompanyDetails cn ON rm.movie_id = cn.movie_id
    LEFT JOIN 
        movie_info i ON rm.movie_id = i.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, am.actor_count, am.main_actor, cn.company_count, rm.total_movies, rm.title_rank
)
SELECT 
    cm.movie_id,
    cm.title,
    cm.production_year,
    cm.actor_count,
    cm.main_actor,
    cm.rank_over_total,
    cm.info_status
FROM 
    CompleteMovieInfo cm
WHERE 
    (cm.actor_count > 3 OR cm.main_actor IS NOT NULL)
ORDER BY 
    cm.production_year DESC, cm.title ASC
LIMIT 20;
