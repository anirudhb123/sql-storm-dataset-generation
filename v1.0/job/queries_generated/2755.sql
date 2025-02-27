WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON ci.movie_id = cc.movie_id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY
        t.title, t.production_year
),
TopActors AS (
    SELECT 
        a.name AS actor_name,
        COUNT(*) AS movie_count
    FROM
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id IN (SELECT id FROM aka_title WHERE production_year = rm.production_year)
    GROUP BY 
        a.name
    HAVING 
        COUNT(*) > (
            SELECT AVG(q.actor_count) FROM RankedMovies q WHERE q.year_rank = 1
        )
),
CompanyStats AS (
    SELECT
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS movies_produced
    FROM
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    GROUP BY 
        cn.name
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 10
)
SELECT 
    rm.title,
    rm.production_year,
    ta.actor_name,
    cs.company_name,
    cs.movies_produced
FROM 
    RankedMovies rm
JOIN 
    TopActors ta ON ta.movie_count = rm.actor_count
JOIN 
    movie_companies mc ON rm.title IN (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    CompanyStats cs ON cs.movies_produced >= 10
WHERE 
    rm.year_rank = 1
ORDER BY
    rm.production_year DESC, rm.actor_count DESC;
