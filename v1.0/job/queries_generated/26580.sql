WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000  -- Focus on more recent films
), 
TopActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT rm.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT rm.movie_id) > 5  -- Actors with more than 5 movies
),
KeywordAnalysis AS (
    SELECT 
        t.title,
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, k.keyword
    HAVING 
        COUNT(mk.movie_id) > 10  -- Keywords applied to more than 10 movies
)
SELECT 
    ta.actor_name,
    ra.title AS movie_title,
    ra.production_year,
    ka.keyword AS relevant_keyword,
    ka.keyword_count
FROM 
    TopActors ta
JOIN 
    RankedMovies ra ON ra.rank = 1  -- Only the top role in each movie
JOIN 
    KeywordAnalysis ka ON ra.title = ka.title
ORDER BY 
    ta.actor_name, ra.production_year DESC, ka.keyword_count DESC;
