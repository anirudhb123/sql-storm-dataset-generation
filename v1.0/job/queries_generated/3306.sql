WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ak.name || ' as ' || rt.role ORDER BY ak.name SEPARATOR ', ') AS cast_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        role_type rt ON ci.person_role_id = rt.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_info,
    COALESCE(mk.keywords, 'No keywords available') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    (SELECT 
         mk.movie_id,
         STRING_AGG(mk.keyword, ', ') AS keywords
     FROM 
         movie_keyword mk
     JOIN 
         keyword k ON mk.keyword_id = k.id
     GROUP BY 
         mk.movie_id) mk ON md.movie_id = mk.movie_id
ORDER BY 
    md.production_year DESC, 
    md.cast_info IS NULL, 
    md.title;
