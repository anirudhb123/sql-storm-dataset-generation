
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
MoviesWithCompanies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_actors,
        cm.company_name,
        cm.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.title = (SELECT m.title FROM aka_title m WHERE m.id = cm.movie_id LIMIT 1)
    WHERE 
        rm.rank <= 10
), 
ActorInfo AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_with_actor
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
)

SELECT 
    mwc.title,
    mwc.production_year,
    mwc.total_actors,
    mwc.company_name,
    mwc.company_type,
    ai.actor_name,
    ai.movies_with_actor
FROM 
    MoviesWithCompanies mwc
LEFT JOIN 
    ActorInfo ai ON ai.movie_id IN (SELECT t.id FROM aka_title t WHERE t.title = mwc.title)
WHERE 
    ai.movies_with_actor IS NOT NULL
ORDER BY 
    mwc.production_year DESC, mwc.total_actors DESC;
