WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        ci.movie_id, 
        ci.nr_order 
    FROM aka_name a 
    JOIN cast_info ci ON a.person_id = ci.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM movie_keyword mk 
    JOIN keyword k ON mk.keyword_id = k.id 
    GROUP BY mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        STRING_AGG(DISTINCT cn.name, ', ') AS companies 
    FROM movie_companies mc 
    JOIN company_name cn ON mc.company_id = cn.id 
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_title, 
    rm.production_year,
    ad.actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.companies, 'No Companies') AS companies
FROM RankedMovies rm
LEFT JOIN ActorDetails ad ON rm.movie_id = ad.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE rm.rank <= 5 AND rm.production_year > 2000
ORDER BY rm.production_year DESC, rm.movie_title;
