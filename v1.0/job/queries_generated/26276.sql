WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MostPopularGenres AS (
    SELECT 
        kt.kind AS genre, 
        COUNT(mt.id) AS movie_count
    FROM 
        aka_title mt
    JOIN 
        kind_type kt ON mt.kind_id = kt.id
    GROUP BY 
        kt.kind
    ORDER BY 
        movie_count DESC
    LIMIT 5
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        rm.actor_count,
        rm.keyword_count,
        r.genre
    FROM 
        RankedMovies rm
    JOIN 
        MostPopularGenres r ON rm.rank <= 5
)

SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    t.actor_count AS Actor_Count,
    t.keyword_count AS Keyword_Count,
    mp.genre AS Genre
FROM 
    TopRankedMovies t
JOIN 
    aka_title a ON t.movie_id = a.id
JOIN 
    kind_type kt ON a.kind_id = kt.id
WHERE 
    t.actor_count > 0 
ORDER BY 
    t.production_year DESC, 
    t.actor_count DESC;
