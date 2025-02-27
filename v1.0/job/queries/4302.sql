WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rnk
    FROM
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
PopularActors AS (
    SELECT 
        a.id AS actor_id, 
        a.name, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    pa.name AS top_actor,
    COALESCE(co.company_name, 'Independent') AS company_name
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON pa.movie_count = (SELECT MAX(movie_count) FROM PopularActors)
LEFT JOIN 
    CompanyMovies co ON rm.movie_id = co.movie_id
WHERE 
    rm.rnk = 1 AND rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.title;
