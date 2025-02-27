WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ka.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ka.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ca ON m.id = ca.movie_id
    LEFT JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    ts.company_count,
    ts.company_names,
    tm.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyStats ts ON tm.movie_id = ts.movie_id
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
