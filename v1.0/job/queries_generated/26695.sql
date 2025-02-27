WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighActorMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count, 
        keywords
    FROM 
        RankedMovies
    WHERE 
        actor_count > 10
),
FinalResults AS (
    SELECT 
        ham.movie_id,
        ham.title,
        ham.production_year,
        ham.actor_count,
        ham.keywords,
        cn.name AS company_name,
        ci.kind AS company_type
    FROM 
        HighActorMovies ham
    LEFT JOIN 
        movie_companies mc ON ham.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ci ON mc.company_type_id = ci.id
    ORDER BY 
        ham.production_year DESC, 
        ham.actor_count DESC
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_count,
    keywords,
    COALESCE(company_name, 'Independent') AS company_name,
    COALESCE(company_type, 'N/A') AS company_type
FROM 
    FinalResults
LIMIT 50;
