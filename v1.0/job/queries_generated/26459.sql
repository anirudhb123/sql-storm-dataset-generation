WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        c.kind AS company_type,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
ActorStats AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        AVG(m.production_year) AS avg_production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        a.name
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_type,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_type,
    tm.keyword_count,
    as.actor_name,
    as.total_movies,
    as.avg_production_year
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.title = ci.movie_id
JOIN 
    aka_name as ON ci.person_id = as.person_id
ORDER BY 
    tm.production_year DESC, tm.keyword_count DESC;
