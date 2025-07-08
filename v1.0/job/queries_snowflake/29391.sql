WITH RankedActors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
TopMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 10
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.id) > 1
)
SELECT 
    ra.actor_name,
    ra.movie_count,
    tm.title AS movie_title,
    tm.production_year,
    mwk.keyword AS movie_keyword,
    mwk.keyword_count
FROM 
    RankedActors ra
JOIN 
    cast_info ci ON ra.actor_id = ci.person_id
JOIN 
    TopMovies tm ON ci.movie_id = tm.movie_id
JOIN 
    MoviesWithKeywords mwk ON tm.movie_id = mwk.movie_id
WHERE 
    mwk.keyword ILIKE '%action%'
ORDER BY 
    ra.rank, tm.production_year DESC, mwk.keyword_count DESC;
