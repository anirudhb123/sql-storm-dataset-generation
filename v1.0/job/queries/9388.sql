WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        actor_count,
        company_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
)
SELECT 
    pm.movie_id,
    pm.title,
    pm.production_year,
    pm.actor_count,
    pm.company_names,
    pm.keywords
FROM 
    PopularMovies pm
ORDER BY 
    pm.production_year DESC, 
    pm.actor_count DESC
LIMIT 10;
