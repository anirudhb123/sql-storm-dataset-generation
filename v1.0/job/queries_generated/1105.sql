WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        ca.person_id,
        COUNT(*) AS movie_count
    FROM 
        cast_info ca
    JOIN 
        RankedTitles rt ON ca.movie_id = rt.title_id
    GROUP BY 
        ca.person_id
    HAVING 
        COUNT(*) >= 5
),
ActorNames AS (
    SELECT 
        a.person_id,
        STRING_AGG(a.name, ', ') AS actor_names
    FROM 
        aka_name a
    INNER JOIN 
        TopActors ta ON a.person_id = ta.person_id
    GROUP BY 
        a.person_id
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
    rt.title,
    rt.production_year,
    an.actor_names,
    cm.company_name,
    cm.company_type,
    mk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    cast_info ci ON ci.movie_id = rt.title_id
LEFT JOIN 
    ActorNames an ON ci.person_id = an.person_id
LEFT JOIN 
    CompanyMovies cm ON cm.movie_id = rt.title_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rt.title_id
WHERE 
    (cm.company_name IS NOT NULL OR an.actor_names IS NOT NULL)
    AND rt.title_rank <= 3
ORDER BY 
    rt.production_year DESC, rt.title;
