
WITH RECURSIVE RankedMovies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastSummary AS (
    SELECT 
        ci.movie_id, 
        COUNT(*) AS actor_count, 
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT c.name) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS rating,
        MAX(CASE WHEN it.info = 'duration' THEN mi.info END) AS duration
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cs.actor_count, 0) AS actor_count,
    COALESCE(cs.actor_names, 'No actors') AS actor_names,
    COALESCE(mcom.company_count, 0) AS company_count,
    COALESCE(mcom.company_names, 'No companies') AS company_names,
    COALESCE(mi.rating, 'No rating') AS rating,
    COALESCE(mi.duration, 'No duration') AS duration
FROM 
    RankedMovies rm
LEFT JOIN 
    CastSummary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    MovieCompanies mcom ON rm.movie_id = mcom.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 10 
ORDER BY 
    rm.production_year DESC;
