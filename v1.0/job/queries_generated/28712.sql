WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        cn.country_code = 'USA'
        AND t.production_year >= 2000
        AND t.title IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        director_name,
        actor_count,
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    director_name,
    actor_count,
    keywords
FROM 
    TopRankedMovies
WHERE 
    rank <= 10
ORDER BY 
    actor_count DESC;
