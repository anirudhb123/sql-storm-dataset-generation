WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    ta.name AS actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    RANK() OVER (PARTITION BY rm.production_year ORDER BY rm.production_year DESC) AS rank_per_year
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    TopActors ta ON ci.person_id = ta.person_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rank_per_year;
