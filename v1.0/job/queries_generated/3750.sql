WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.note DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        kc.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        ActorCounts ac ON rm.title_id = ac.movie_id
    JOIN 
        KeywordCounts kc ON rm.title_id = kc.movie_id
    WHERE 
        rm.rank <= 3
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS actor_count,
    COALESCE(tm.keyword_count, 0) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    aka_title at ON tm.title_id = at.movie_id
LEFT JOIN 
    aka_name an ON at.id = an.id
WHERE 
    an.name IS NULL
ORDER BY 
    tm.production_year DESC, 
    tm.title;
