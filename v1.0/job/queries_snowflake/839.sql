
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_in_year
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cd.total_cast, 0) AS total_cast,
        COALESCE(cd.cast_names, 'None') AS cast_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
),
RecentMovies AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        mwc.total_cast,
        mwc.cast_names,
        LEAD(mwc.production_year) OVER (ORDER BY mwc.production_year) AS next_production_year
    FROM 
        MoviesWithCast mwc
    WHERE 
        mwc.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
)
SELECT 
    r.title,
    r.production_year,
    r.total_cast,
    r.cast_names,
    CASE 
        WHEN r.production_year = r.next_production_year THEN 'Consecutive'
        WHEN r.next_production_year IS NULL THEN 'Latest'
        ELSE 'Gap'
    END AS production_gap
FROM 
    RecentMovies r
WHERE 
    r.total_cast > 5
ORDER BY 
    r.production_year DESC, 
    r.total_cast DESC;
