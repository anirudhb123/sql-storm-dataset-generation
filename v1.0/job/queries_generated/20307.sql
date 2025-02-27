WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        movie_rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id, tm.title
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        ci.nr_order <= 3  -- Only the first three roles considered for each actor
    GROUP BY 
        a.id, a.name
),
FilmCompanyInfo AS (
    SELECT 
        c.id AS company_id,
        c.name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT t.title, ', ') AS produced_movies
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON c.id = mc.company_id
    LEFT JOIN 
        aka_title t ON mc.movie_id = t.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        c.id, c.name, ct.kind
)
SELECT 
    tm.title AS movie_title,
    tm.production_year,
    ai.actor_name,
    ai.movie_count AS total_roles,
    fci.name AS company_name,
    fci.company_type,
    fci.produced_movies,
    tw.keywords
FROM 
    MoviesWithKeywords tw
JOIN 
    TopMovies tm ON tw.movie_id = tm.movie_id
JOIN 
    ActorInfo ai ON ai.movies LIKE CONCAT('%', tm.title, '%')  -- Filter actors involved in the movie
LEFT JOIN 
    FilmCompanyInfo fci ON fci.produced_movies LIKE CONCAT('%', tm.title, '%')
WHERE 
    ai.movie_count >= 1 
    AND (fci.company_type IS NOT NULL OR fci.company_name IS NULL)  -- NULL logic check
ORDER BY 
    tm.production_year DESC, 
    ai.movie_count DESC, 
    fci.name ASC
LIMIT 100
OFFSET 0;
