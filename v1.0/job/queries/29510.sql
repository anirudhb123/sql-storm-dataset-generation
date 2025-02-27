WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(mc.company_id) AS num_companies,
        COUNT(DISTINCT mk.keyword_id) AS num_keywords,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_companies,
        num_keywords,
        rank
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
ActorsInTopMovies AS (
    SELECT 
        DISTINCT ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        TopMovies t
    JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
)
SELECT 
    a.actor_name,
    a.movie_title,
    a.production_year,
    COUNT(a.actor_name) OVER (PARTITION BY a.actor_name) AS film_count
FROM 
    ActorsInTopMovies a
ORDER BY 
    film_count DESC, a.actor_name;
