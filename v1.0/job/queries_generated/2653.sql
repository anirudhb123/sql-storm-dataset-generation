WITH MovieDetails AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        keywords, 
        RANK() OVER (ORDER BY actor_count DESC) as rank
    FROM 
        MovieDetails
)

SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    CASE 
        WHEN tm.keywords IS NULL THEN 'No keywords'
        ELSE UNNEST(tm.keywords)
    END AS keyword,
    COALESCE(NULLIF(AVG(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END), 0), 'No orders') AS avg_order
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
