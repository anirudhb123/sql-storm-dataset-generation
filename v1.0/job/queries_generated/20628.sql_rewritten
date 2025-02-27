WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id
),
NullFiltering AS (
    SELECT 
        title_id,
        title,
        production_year,
        COALESCE(NULLIF(keywords[1], ''), 'No Keywords') AS prominent_keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MoviesWithKeywords mw ON rm.title_id = mw.movie_id
),
OuterJoinDetails AS (
    SELECT 
        nf.title,
        nf.production_year,
        ac.movie_count,
        CASE 
            WHEN nf.prominent_keyword IS NULL THEN 'No Keywords Available'
            ELSE nf.prominent_keyword
        END AS final_keyword
    FROM 
        NullFiltering nf
    LEFT JOIN 
        ActorMovieCounts ac ON nf.production_year = ac.movie_count
)
SELECT 
    oj.title,
    oj.production_year,
    oj.movie_count,
    oj.final_keyword
FROM 
    OuterJoinDetails oj
WHERE 
    (oj.movie_count IS NULL OR oj.movie_count > 5)
    AND (oj.final_keyword IS NOT NULL OR oj.production_year < 2010)
ORDER BY 
    oj.production_year DESC,
    oj.movie_count DESC;