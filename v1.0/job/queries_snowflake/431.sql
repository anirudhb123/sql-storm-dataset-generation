
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), ActorCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ac.movie_count, 0) AS actor_movie_count,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON ac.person_id IN (
        SELECT 
            c.person_id 
        FROM 
            cast_info c 
        WHERE 
            c.movie_id = rm.title_id
    )
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.title_id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC, actor_movie_count DESC
LIMIT 10 OFFSET 0;
