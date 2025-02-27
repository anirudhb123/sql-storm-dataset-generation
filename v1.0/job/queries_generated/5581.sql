WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year,
        RM.actor_count,
        RM.actors
    FROM 
        RankedMovies RM
    WHERE 
        RM.rank <= 5
)
SELECT 
    TM.title,
    TM.production_year,
    TM.actor_count,
    TM.actors,
    COALESCE(CAST(COUNT(DISTINCT mc.company_id) AS TEXT), '0') AS production_companies,
    COALESCE(CAST(STRING_AGG(DISTINCT cn.name, ', ') AS TEXT), 'N/A') AS company_names
FROM 
    TopMovies TM
LEFT JOIN 
    movie_companies mc ON TM.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    TM.movie_id, TM.title, TM.production_year, TM.actor_count, TM.actors
ORDER BY 
    TM.production_year DESC, TM.actor_count DESC;
