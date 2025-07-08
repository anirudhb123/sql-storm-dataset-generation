
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
), 
ActorRoles AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count, 
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
), 
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
), 
RankedMovies AS (
    SELECT 
        md.movie_id, 
        md.movie_title, 
        md.production_year, 
        ar.actor_count, 
        ar.actors, 
        mci.company_count, 
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY ar.actor_count DESC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorRoles ar ON md.movie_id = ar.movie_id
    LEFT JOIN 
        MovieCompanyInfo mci ON md.movie_id = mci.movie_id
)

SELECT 
    rm.movie_id, 
    rm.movie_title, 
    rm.production_year, 
    rm.actor_count, 
    rm.actors, 
    rm.company_count, 
    rm.rank
FROM 
    RankedMovies rm
WHERE 
    rm.company_count IS NOT NULL
ORDER BY 
    rm.production_year, rm.rank;
