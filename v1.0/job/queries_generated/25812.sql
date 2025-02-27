WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.aka_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_keyword mk ON fm.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    fm.title, fm.production_year, fm.cast_count, fm.aka_names
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
