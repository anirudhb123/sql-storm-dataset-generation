WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.company_count, 0) AS total_companies,
    COALESCE(cd.cast_count, 0) AS total_cast,
    COALESCE(cd.actor_names, 'No actors found') AS actors_list
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
