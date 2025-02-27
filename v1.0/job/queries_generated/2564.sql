WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as yearly_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
ActorMovies AS (
    SELECT 
        a.name,
        COUNT(m.id) AS movie_count,
        STRING_AGG(DISTINCT m.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title m ON c.movie_id = m.id
    GROUP BY 
        a.name
),
MovieCompanyDetails AS (
    SELECT 
        t.title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title t ON mc.movie_id = t.id
)
SELECT 
    rm.title,
    rm.production_year,
    mk.keyword_list,
    am.name AS actor_name,
    am.movie_count,
    am.movies,
    mc.company_name,
    mc.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.movie_id
LEFT JOIN 
    ActorMovies am ON rm.title = ANY(am.movies)
LEFT JOIN 
    MovieCompanyDetails mc ON rm.title = mc.title
WHERE 
    rm.yearly_rank <= 5 
    AND (mk.keyword_list IS NOT NULL OR am.movie_count > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
