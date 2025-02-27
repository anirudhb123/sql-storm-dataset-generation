WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    WHERE 
        ci.nr_order IS NOT NULL
    GROUP BY 
        ci.person_id
),
CompCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    a.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    acc.movie_count,
    cc.company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    RankedMovies rm ON ci.movie_id = rm.movie_id
LEFT JOIN 
    ActorMovieCount acc ON a.person_id = acc.person_id
LEFT JOIN 
    CompCompanies cc ON rm.movie_id = cc.movie_id
WHERE 
    acc.movie_count IS NOT NULL AND
    (rm.production_year >= 2000 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, a.name;
