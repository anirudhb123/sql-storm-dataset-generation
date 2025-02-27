WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorCounts AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title AS movie_title,
        rm.production_year,
        kc.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordCount kc ON rm.movie_id = kc.movie_id
    WHERE 
        rm.rank <= 5 OR kc.keyword_count IS NOT NULL
)
SELECT 
    mwk.movie_title,
    mwk.production_year,
    ac.name AS actor_name,
    ac.movie_count,
    mwk.keyword_count
FROM 
    MoviesWithKeywords mwk
JOIN 
    ActorCounts ac ON mwk.movie_id IN (
        SELECT 
            DISTINCT ci.movie_id 
        FROM 
            cast_info ci 
        JOIN 
            aka_name ak ON ci.person_id = ak.person_id 
        WHERE 
            ak.name LIKE '%' || ac.name || '%'
    )
ORDER BY 
    mwk.production_year DESC, mwk.movie_title;
