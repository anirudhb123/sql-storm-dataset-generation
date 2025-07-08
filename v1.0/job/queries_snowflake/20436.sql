WITH RankedMovies AS (
    SELECT 
        tit.id AS title_id,
        tit.title,
        tit.production_year,
        RANK() OVER (PARTITION BY tit.production_year ORDER BY tit.id) AS rank_within_year
    FROM 
        aka_title tit
    WHERE 
        tit.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        CASE WHEN cn.country_code IS NULL THEN 'Unknown' ELSE cn.country_code END AS country
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),
MoviesWithActors AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT am.actor_name) AS total_actors,
        COALESCE(MAX(cd.company_name), 'No Company') AS production_company,
        COALESCE(MAX(cd.country), 'No Country') AS company_country
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.title_id = am.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rm.title_id = cd.movie_id
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
),
FinalReport AS (
    SELECT 
        mwa.title,
        mwa.production_year,
        mwa.total_actors,
        mwa.production_company,
        mwa.company_country,
        CASE 
            WHEN mwa.production_year < 2000 THEN 'Classic'
            WHEN mwa.production_year IS NULL THEN 'Year Unknown'
            ELSE 'Modern'
        END AS film_era,
        CASE 
            WHEN mwa.total_actors > 10 THEN 'Ensemble Cast'
            WHEN mwa.total_actors IS NULL THEN 'No Actors'
            ELSE 'Small Cast'
        END AS cast_category
    FROM 
        MoviesWithActors mwa
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.total_actors IS NOT NULL AND fr.total_actors > 5 THEN 'Diverse Cast'
        ELSE 'Limited Cast'
    END AS diversity_category,
    CASE 
        WHEN fr.production_year % 2 = 0 THEN 'Even Year'
        ELSE 'Odd Year'
    END AS year_type
FROM 
    FinalReport fr
WHERE 
    fr.production_year >= 1990
ORDER BY 
    fr.production_year DESC, 
    fr.total_actors DESC, 
    fr.title;
