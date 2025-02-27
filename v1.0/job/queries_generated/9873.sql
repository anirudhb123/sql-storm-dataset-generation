WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND ci.nr_order < 3
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, title
    ORDER BY 
        actor_count DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.actor_count,
    tm.keywords,
    (SELECT COUNT(*) FROM MovieDetails md WHERE md.movie_id = tm.movie_id) AS total_movies_with_keyword
FROM 
    TopMovies tm
ORDER BY 
    tm.actor_count DESC;
