WITH ActorTitles AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
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
),
RecentMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        company_name,
        company_type,
        keywords
    FROM 
        ActorTitles a
    LEFT JOIN 
        MovieCompanies mc ON a.movie_title = mc.movie_id
    LEFT JOIN 
        MovieKeywords mk ON a.movie_title = mk.movie_id
    WHERE 
        a.recent_movie_rank = 1
)

SELECT 
    actor_name,
    movie_title,
    production_year,
    COALESCE(company_name, 'Independent') AS company_name,
    COALESCE(company_type, 'N/A') AS company_type,
    COALESCE(keywords, 'No keywords') AS keywords,
    CASE 
        WHEN production_year IS NULL THEN 'Unknown Year'
        WHEN production_year < 1920 THEN 'Silent Era'
        WHEN production_year BETWEEN 1920 AND 1970 THEN 'Classic Era'
        ELSE 'Modern Era'
    END AS era_classification
FROM 
    RecentMovies
ORDER BY 
    production_year DESC, actor_name;
