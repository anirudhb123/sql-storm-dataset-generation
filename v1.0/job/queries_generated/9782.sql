WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        k.keyword
    FROM 
        TopMovies tm
    JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MoviesWithCast AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.keyword,
        a.name AS actor_name
    FROM 
        MoviesWithKeywords mwk
    JOIN 
        cast_info ci ON mwk.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order < 3
),
FinalResults AS (
    SELECT 
        mwk.title,
        mwk.production_year,
        mwk.keyword,
        STRING_AGG(DISTINCT mwc.actor_name, ', ') AS actors
    FROM 
        MoviesWithCast mwc
    GROUP BY 
        mwc.title, mwc.production_year, mwc.keyword
)
SELECT 
    f.title,
    f.production_year,
    f.keyword,
    f.actors
FROM 
    FinalResults f
ORDER BY 
    f.production_year DESC, f.title;
