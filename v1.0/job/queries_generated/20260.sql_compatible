
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title ASC) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedTitles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ci.person_id
),
DistinctActors AS (
    SELECT 
        ak.name,
        ak.id AS actor_id,
        amc.movie_count
    FROM 
        aka_name ak
    LEFT JOIN 
        ActorMovieCount amc ON ak.person_id = amc.person_id
    WHERE 
        ak.name IS NOT NULL
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    dt.actor_id,
    dt.name AS actor_name,
    dt.movie_count,
    mt.title,
    mt.production_year,
    mcd.company_names,
    mcd.total_companies
FROM 
    DistinctActors dt
JOIN 
    cast_info ci ON dt.actor_id = ci.person_id
JOIN 
    RankedTitles mt ON ci.movie_id = mt.title_id
LEFT JOIN 
    MovieCompanyDetails mcd ON mt.title_id = mcd.movie_id
WHERE 
    dt.movie_count >= (
        SELECT 
            AVG(movie_count) 
        FROM 
            ActorMovieCount
    )
    AND mcd.total_companies > 1 
ORDER BY 
    dt.name ASC, mt.production_year DESC;
