
WITH 
    RankedMovies AS (
        SELECT 
            at.id AS movie_id, 
            at.title, 
            at.production_year, 
            ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS year_rank
        FROM 
            aka_title at
        WHERE 
            at.production_year IS NOT NULL
    ),
    ActorCounts AS (
        SELECT 
            ci.movie_id, 
            COUNT(DISTINCT ci.person_id) AS actor_count
        FROM 
            cast_info ci
        GROUP BY 
            ci.movie_id
    ),
    MovieInfo AS (
        SELECT 
            mt.movie_id, 
            STRING_AGG(mi.info, ', ') AS info_details
        FROM 
            movie_info mt
        JOIN 
            movie_info_idx mi ON mt.movie_id = mi.movie_id
        GROUP BY 
            mt.movie_id
    ),
    CompanyDetails AS (
        SELECT 
            mc.movie_id, 
            STRING_AGG(DISTINCT cn.name, ', ') AS companies,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id
        GROUP BY 
            mc.movie_id
    ),
    CoCastLinks AS (
        SELECT 
            m.movie_id, 
            COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count
        FROM 
            movie_link ml
        JOIN 
            complete_cast m ON ml.movie_id = m.movie_id
        GROUP BY 
            m.movie_id
    )
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(cd.companies, 'No companies') AS production_companies,
    COALESCE(cd.company_count, 0) AS total_production_companies,
    COALESCE(co.linked_movies_count, 0) AS total_linked_movies,
    CASE 
        WHEN rm.year_rank IS NULL THEN 'N/A' 
        ELSE CAST(rm.year_rank AS VARCHAR)
    END AS year_rank,
    CASE 
        WHEN COALESCE(ac.actor_count, 0) > 10 AND COALESCE(co.linked_movies_count, 0) > 2 THEN 'Major Blockbuster' 
        WHEN COALESCE(ac.actor_count, 0) < 5 THEN 'Indie Film' 
        ELSE 'Standard Release' 
    END AS film_category,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CoCastLinks co ON rm.movie_id = co.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
ORDER BY 
    rm.production_year DESC, rm.title ASC;
