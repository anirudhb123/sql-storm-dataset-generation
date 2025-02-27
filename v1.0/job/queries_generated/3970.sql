WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
TopActors AS (
    SELECT 
        actor_name,
        SUM(role_count) AS total_roles
    FROM 
        ActorMovies
    GROUP BY 
        actor_name
    HAVING 
        SUM(role_count) > 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ta.actor_name,
    tk.keywords,
    cm.company_name
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.movie_id = ta.actor_name
LEFT JOIN 
    MovieKeywords tk ON rm.movie_id = tk.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.movie_id;
