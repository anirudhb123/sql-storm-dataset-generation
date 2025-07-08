
WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.id) DESC) AS rn
    FROM
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.actor_name,
        rm.cast_count,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.title_id = mk.movie_id
    WHERE 
        rm.rn = 1 
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    tm.cast_count,
    tm.keywords
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC
LIMIT 
    10;
