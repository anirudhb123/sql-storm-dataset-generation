WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
),
CastingInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT na.name, ', ') AS actor_names
    FROM
        cast_info ci
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    GROUP BY 
        ci.movie_id
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
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(ci.actor_count, 0) AS actor_count,
    COALESCE(ci.actor_names, 'No Actors') AS actor_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN '21st Century'
        WHEN tm.production_year < 2000 THEN 'Before 2000'
        ELSE 'Future'
    END AS production_period
FROM 
    TopMovies tm
LEFT JOIN 
    CastingInfo ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    (tm.production_year IS NULL OR tm.production_year > 1990) 
    AND (COALESCE(ci.actor_count, 0) > 2 OR mk.keywords IS NOT NULL)
ORDER BY 
    tm.production_year DESC, tm.title ASC;