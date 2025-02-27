WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) as rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    am.actor_name,
    km.keywords,
    cm.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovies am ON rm.movie_id = am.movie_id AND am.actor_rank <= 3
LEFT JOIN 
    KeywordMovies km ON rm.movie_id = km.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.movie_id;
