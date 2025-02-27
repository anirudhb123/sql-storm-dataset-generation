WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) as title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TitleKeywords AS (
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
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorMovies AS (
    SELECT 
        r.actor_name,
        r.movie_title,
        r.production_year,
        tk.keywords,
        COALESCE(mc.company_names, 'No Companies') AS companies,
        COALESCE(mc.company_count, 0) AS company_count
    FROM 
        RankedTitles r
    LEFT JOIN 
        TitleKeywords tk ON r.movie_title = tk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON r.movie_title = mc.movie_id
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keywords,
    companies,
    company_count
FROM 
    ActorMovies
WHERE 
    title_rank = 1
ORDER BY 
    production_year DESC, actor_name;
