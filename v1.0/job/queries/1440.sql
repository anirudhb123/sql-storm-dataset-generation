WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        m.movie_id,
        m.title,
        m.production_year,
        m.actor_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        RankedMovies m ON c.movie_id = m.movie_id
    WHERE 
        m.rank <= 5
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    a.actor_name,
    a.title,
    a.production_year,
    COALESCE(cm.company_count, 0) AS company_count
FROM 
    ActorInfo a
LEFT JOIN 
    CompanyMovieCounts cm ON a.movie_id = cm.movie_id
WHERE 
    a.actor_name IS NOT NULL
ORDER BY 
    a.production_year DESC, a.actor_name;
