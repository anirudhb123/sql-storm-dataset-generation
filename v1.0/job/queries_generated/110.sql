WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        c.movie_id,
        c.nr_order,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword k ON c.movie_id = k.movie_id
    GROUP BY 
        ak.id, ak.name, c.movie_id, c.nr_order
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ad.name AS actor_name,
    ad.keywords,
    mcd.company_count,
    mcd.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
WHERE 
    rm.movie_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.movie_id;
