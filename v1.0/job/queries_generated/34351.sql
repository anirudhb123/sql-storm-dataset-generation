WITH RECURSIVE ActorMovies AS (
    SELECT 
        c.id AS cast_id,
        a.id AS actor_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
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
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FullMovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(cd.companies, 'No Companies') AS companies,
        COALESCE(cd.company_types, 'No Company Types') AS company_types
    FROM 
        aka_title t
    LEFT JOIN 
        MovieKeywords mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        CompanyDetails cd ON t.movie_id = cd.movie_id
),
TopActors AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        ActorMovies
    WHERE 
        movie_rank <= 5
    GROUP BY 
        actor_id
    HAVING 
        movie_count >= 2
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    fam.movie_id,
    fam.title,
    fam.production_year,
    fam.keywords,
    fam.companies,
    fam.company_types
FROM 
    TopActors ta
JOIN 
    ActorMovies am ON ta.actor_id = am.actor_id
JOIN 
    FullMovieDetails fam ON am.title = fam.title AND am.production_year = fam.production_year
JOIN 
    aka_name a ON ta.actor_id = a.id
WHERE 
    am.movie_rank = 1
ORDER BY 
    a.name, fam.production_year DESC;
