
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CharDetails AS (
    SELECT 
        c.id AS char_id,
        c.name,
        c.imdb_index,
        c.imdb_id,
        ROW_NUMBER() OVER (PARTITION BY c.name ORDER BY c.imdb_id DESC) AS char_rank
    FROM 
        char_name c
    WHERE 
        c.name IS NOT NULL
),
FullCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        MAX(comp.kind) AS company_type
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = ci.movie_id
    LEFT JOIN 
        company_type comp ON comp.id = mc.company_type_id
    GROUP BY 
        ci.movie_id, ak.name
),
MoviesWithKeywords AS (
    SELECT 
        t.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mkw
    JOIN 
        keyword k ON k.id = mkw.keyword_id
    JOIN 
        aka_title t ON t.id = mkw.movie_id
    GROUP BY 
        t.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rc.actor_name,
    rc.company_type,
    COALESCE(mkw.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.total_movies > 5 THEN 'Popular Year' 
        ELSE 'Less Popular Year' 
    END AS movie_popularity,
    CASE 
        WHEN cd.char_rank IS NULL THEN 'Unknown Character'
        ELSE 'Known Character'
    END AS character_status
FROM 
    RankedMovies rm
JOIN 
    FullCast rc ON rm.movie_id = rc.movie_id
LEFT JOIN 
    MoviesWithKeywords mkw ON rm.movie_id = mkw.movie_id
LEFT JOIN 
    CharDetails cd ON cd.name = rc.actor_name
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rc.actor_name ASC
LIMIT 100;
