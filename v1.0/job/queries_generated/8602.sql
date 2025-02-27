WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ka.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ka.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    GROUP BY 
        t.title, t.production_year, t.kind_id
),
HighActorMovies AS (
    SELECT 
        title,
        production_year,
        kind_id,
        company_count,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    ham.title,
    ham.production_year,
    kt.kind,
    ham.company_count,
    ham.actor_count
FROM 
    HighActorMovies ham
JOIN 
    kind_type kt ON ham.kind_id = kt.id
ORDER BY 
    ham.production_year, ham.actor_count DESC;
