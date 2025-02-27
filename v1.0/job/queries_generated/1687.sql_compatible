
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        c.name AS company_name, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        t.id AS movie_id
    FROM 
        aka_title t
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year IS NOT NULL
),

MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(rm.company_name, 'Unknown') AS company_name,
    mk.keywords,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id = rm.movie_id AND ci.note IS NOT NULL) AS actor_count,
    (SELECT AVG(CAST(info AS numeric)) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.movie_id AND mi.note = 'rating') AS avg_rating
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 100;
