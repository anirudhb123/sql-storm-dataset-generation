WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 3
),
MovieDetails AS (
    SELECT 
        tm.title_id,
        tm.title,
        COALESCE(COUNT(ci.id), 0) AS cast_count,
        ARRAY_AGG(DISTINCT cn.name) AS cast_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = tm.title_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name cn ON cn.person_id = ci.person_id
    GROUP BY 
        tm.title_id, tm.title
),
MovieKeywords AS (
    SELECT 
        mw.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mw
    JOIN 
        keyword k ON k.id = mw.keyword_id
    GROUP BY 
        mw.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = md.title_id
WHERE 
    md.cast_count > 0
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
