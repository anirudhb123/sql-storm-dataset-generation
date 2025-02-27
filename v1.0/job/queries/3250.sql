WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), ActorDetails AS (
    SELECT
        a.name AS actor_name,
        a.person_id,
        m.title AS movie_title,
        m.production_year
    FROM
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
), MoviesWithKeywords AS (
    SELECT
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT ad.actor_name) AS total_actors,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN m.production_year IS NOT NULL THEN 1 ELSE 0 END) AS valid_year_count
FROM 
    RankedMovies m
LEFT JOIN 
    ActorDetails ad ON m.title = ad.movie_title AND m.production_year = ad.production_year
LEFT JOIN 
    MoviesWithKeywords kw ON m.title = kw.title AND m.production_year = kw.production_year
WHERE 
    m.rank <= 10
GROUP BY 
    m.title, m.production_year
ORDER BY 
    m.production_year DESC, total_actors DESC;
