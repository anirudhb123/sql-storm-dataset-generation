WITH MovieData AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ci.nr_order,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        a.name, t.title, t.production_year, ci.nr_order
),
FilteredMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        keyword_count
    FROM 
        MovieData
    WHERE 
        production_year >= 2000 AND keyword_count > 0
),
TopMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS movie_rank
    FROM 
        FilteredMovies
)
SELECT 
    t.actor_name,
    t.movie_title,
    t.production_year,
    t.keyword_count,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    COALESCE(mn.info, 'No info') AS additional_info
FROM 
    TopMovies t
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = t.movie_title LIMIT 1)
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mn ON mn.movie_id = (SELECT id FROM aka_title WHERE title = t.movie_title LIMIT 1)
WHERE 
    t.movie_rank <= 10
ORDER BY 
    t.keyword_count DESC, t.production_year ASC;
