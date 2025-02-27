WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies,
        AVG(production_year) AS avg_production_year
    FROM 
        RankedTitles
    WHERE 
        rank <= 10
    GROUP BY 
        actor_name
),
CompanyMovies AS (
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
    WHERE 
        c.country_code = 'USA'
),
FeaturedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    a.actor_name,
    a.total_movies,
    a.avg_production_year,
    cm.company_name,
    cm.company_type,
    fm.title,
    fm.production_year,
    fm.keyword_count
FROM 
    ActorStats a
JOIN 
    CompanyMovies cm ON a.total_movies > 5
LEFT JOIN 
    FeaturedMovies fm ON a.avg_production_year >= fm.production_year - 5
ORDER BY 
    a.total_movies DESC, fm.keyword_count DESC
LIMIT 50;
