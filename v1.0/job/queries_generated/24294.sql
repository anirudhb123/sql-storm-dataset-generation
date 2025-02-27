WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast_count <= 5
),
CoActors AS (
    SELECT 
        c1.person_id AS actor_id,
        c1.movie_id AS movie_id,
        COUNT(c2.person_id) AS co_actor_count
    FROM 
        cast_info c1
    JOIN 
        cast_info c2 ON c1.movie_id = c2.movie_id AND c1.person_id <> c2.person_id
    GROUP BY 
        c1.person_id, c1.movie_id
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COALESCE(c.co_actor_count, 0) AS co_actor_count
    FROM 
        aka_name a
    LEFT JOIN 
        CoActors c ON a.person_id = c.actor_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    ad.name AS actor_name,
    ad.co_actor_count,
    CASE 
        WHEN ad.co_actor_count >= 10 THEN 'Star'
        WHEN ad.co_actor_count BETWEEN 5 AND 9 THEN 'Notable'
        ELSE 'Ensemble'
    END AS actor_status,
    STRING_AGG(DISTINCT k.keyword, ', ' ORDER BY k.keyword) AS keywords
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    ActorDetails ad ON ci.person_id = ad.actor_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, ad.actor_id, ad.name, ad.co_actor_count
HAVING
    COUNT(DISTINCT ad.actor_id) > 2
ORDER BY 
    tm.production_year DESC, tm.movie_id;
