WITH RecursiveActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        c.nr_order = 1
),
HighlightedMovies AS (
    SELECT 
        r.actor_id,
        r.actor_name,
        r.movie_id,
        r.movie_title,
        r.production_year
    FROM 
        RecursiveActorMovies r
    WHERE 
        r.year_rank <= 5
),
MovieKeywordCTE AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
ActorMoviesWithKeywords AS (
    SELECT 
        h.actor_id,
        h.actor_name,
        h.movie_id,
        h.movie_title,
        h.production_year,
        k.keywords
    FROM 
        HighlightedMovies h
    LEFT JOIN 
        MovieKeywordCTE k ON h.movie_id = k.movie_id
),
MovieCompanyData AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
),
FinalResults AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        am.movie_id,
        am.movie_title,
        COALESCE(am.keywords, 'No Keywords') AS keywords,
        COALESCE(mc.companies, 'No Companies') AS companies,
        CASE 
            WHEN am.production_year < 2000 THEN 'Classic'
            WHEN am.production_year BETWEEN 2000 AND 2015 THEN 'Contemporary'
            ELSE 'Recent'
        END AS category
    FROM 
        ActorMoviesWithKeywords am
    FULL OUTER JOIN 
        MovieCompanyData mc ON am.movie_id = mc.movie_id
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keywords,
    companies,
    category
FROM 
    FinalResults
WHERE 
    keywords IS NOT NULL
    OR companies IS NOT NULL
ORDER BY 
    actor_name, production_year DESC
LIMIT 100;
