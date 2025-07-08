WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_within_year
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), NoteworthyActors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ci.movie_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.person_id) > 1
), MovieCompaniesWithInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mi.info, 'No additional information') AS info
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = mc.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary' LIMIT 1)
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        na.actor_name,
        COUNT(DISTINCT mci.company_name) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.production_year DESC) AS year_rank,
        CAST(RTRIM(rm.title) || ' (' || rm.production_year || ')' AS VARCHAR(255)) AS full_title
    FROM 
        RankedMovies rm
    LEFT JOIN 
        NoteworthyActors na ON na.movie_id = rm.movie_id
    LEFT JOIN 
        MovieCompaniesWithInfo mci ON mci.movie_id = rm.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, na.actor_name
)
SELECT 
    md.full_title,
    md.production_year,
    COALESCE(md.actor_name, 'No main actors') AS leading_actor,
    md.company_count,
    md.year_rank
FROM 
    MovieDetails md
WHERE 
    md.company_count > 0
ORDER BY 
    md.production_year DESC, md.full_title ASC;
