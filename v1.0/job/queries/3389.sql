
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(c.movie_id) > 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(pa.name, 'Unknown Actor') AS top_actor,
    COALESCE(pa.movie_count, 0) AS actor_movie_count,
    cm.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON pa.actor_id = (
        SELECT a.id 
        FROM aka_name a 
        JOIN cast_info c ON a.person_id = c.person_id 
        WHERE c.movie_id = rm.movie_id 
        GROUP BY a.id, a.name 
        ORDER BY COUNT(c.movie_id) DESC 
        LIMIT 1
    )
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.title;
