WITH RankedActors AS (
    SELECT 
        a.name AS actor_name,
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name, a.person_id
),
PopularMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
FavoriteKeywords AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(mk.movie_id) > 3
)
SELECT 
    ra.actor_name,
    ra.movie_count AS total_movies,
    pm.movie_title,
    pm.production_year,
    fk.keyword AS popular_keyword,
    fk.keyword_count
FROM 
    RankedActors ra
JOIN 
    PopularMovies pm ON ra.movie_count > 10
CROSS JOIN 
    FavoriteKeywords fk
WHERE 
    ra.rank <= 10
ORDER BY 
    ra.movie_count DESC, 
    pm.production_year DESC;
