WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.count DESC) AS rank
    FROM 
        title t
    JOIN (
        SELECT 
            movie_id, COUNT(*) AS count
        FROM 
            cast_info 
        GROUP BY 
            movie_id
    ) m ON t.id = m.movie_id
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
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
),
FinalResults AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        STRING_AGG(DISTINCT pa.actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT cm.company_name || ' (' || cm.company_type || ')', '; ') AS companies
    FROM 
        RankedMovies r
    LEFT JOIN 
        PopularActors pa ON pa.movie_count > 5
    LEFT JOIN 
        CompanyMovies cm ON r.title_id = cm.movie_id
    WHERE 
        r.rank <= 10
    GROUP BY 
        r.title_id, r.title, r.production_year
)
SELECT 
    title,
    production_year,
    COALESCE(actors, 'No Actors') AS actors,
    COALESCE(companies, 'No Companies') AS companies
FROM 
    FinalResults
ORDER BY 
    production_year DESC, title;
