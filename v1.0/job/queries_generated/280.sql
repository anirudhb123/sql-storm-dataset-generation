WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT t.id) > 5
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
    tm.title,
    tm.production_year,
    pa.name AS popular_actor,
    mk.keywords
FROM 
    RankedMovies tm
LEFT JOIN 
    PopularActors pa ON tm.actor_rank = 1
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.movie_id
WHERE 
    tm.actor_rank <= 3
ORDER BY 
    tm.production_year DESC, 
    movie_count DESC NULLS LAST;
