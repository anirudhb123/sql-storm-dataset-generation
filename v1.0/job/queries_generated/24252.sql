WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY 
        m.id
),
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(m.production_year) AS last_movie_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.movie_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        as.person_id
    FROM 
        ActorStats as
    WHERE 
        movie_count > (SELECT AVG(movie_count) FROM ActorStats)
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies
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
    ca.name AS actor_name,
    cc.companies,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
    COUNT(DISTINCT ci.person_id) AS cast_count
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    aka_name ca ON ci.person_id = ca.person_id
JOIN 
    CompanyMovieInfo cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 3 
    AND ca.person_id IN (SELECT * FROM TopActors)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ca.name, cc.companies, mk.keyword
ORDER BY 
    rm.production_year DESC, cast_count DESC;

This SQL query combines multiple concepts such as Common Table Expressions (CTEs), window functions, subqueries, and outer joins to aggregate and rank movies based on certain criteria. It captures the complexity of the domain, enabling performance benchmarking of queries against a comprehensive schema like the one you've provided.
