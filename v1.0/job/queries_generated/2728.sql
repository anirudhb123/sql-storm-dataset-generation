WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        k.keyword, 
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) as rank
    FROM 
        MovieDetails
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS total_actors,
    c.name AS company_name,
    c.country_code,
    ci.role_id,
    ROW_NUMBER() OVER(PARTITION BY tm.production_year ORDER BY tm.actor_count DESC) AS row_num
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = cc.movie_id
LEFT JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
WHERE 
    tm.rank <= 5
    AND (c.country_code IS NULL OR c.country_code != 'USA')
ORDER BY 
    tm.production_year, total_actors DESC;
