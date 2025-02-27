WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        at.title,
        at.production_year,
        c.nr_order AS role_order,
        COUNT(DISTINCT m.company_id) AS production_companies
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title at ON c.movie_id = at.movie_id
    LEFT JOIN 
        movie_companies m ON at.movie_id = m.movie_id
    GROUP BY 
        a.name, at.title, at.production_year, c.nr_order
),
MovieKeywords AS (
    SELECT 
        at.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.title
)
SELECT 
    am.actor_name,
    am.title,
    am.production_year,
    am.role_order,
    COALESCE(r.title_rank, 0) AS year_rank,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    CASE 
        WHEN am.production_companies > 1 THEN 'Multi-Company'
        WHEN am.production_companies = 1 THEN 'Single Company'
        ELSE 'No Companies'
    END AS company_status
FROM 
    ActorMovies am
LEFT JOIN 
    RankedTitles r ON am.title = r.title AND am.production_year = r.production_year
LEFT JOIN 
    MovieKeywords mk ON am.title = mk.title
WHERE 
    am.role_order IS NOT NULL
ORDER BY 
    am.production_year DESC, am.actor_name;
