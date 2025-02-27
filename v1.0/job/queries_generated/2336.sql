WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        COALESCE(mk.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
),
MovieActors AS (
    SELECT 
        cm.movie_id,
        ak.name AS actor_name,
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS actor_count
    FROM 
        complete_cast cm
    JOIN 
        cast_info ci ON cm.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        cm.movie_id, ak.name
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank,
    ma.actor_name,
    ma.actor_count,
    mc.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieActors ma ON rm.movie_id = ma.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.rank;
