WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
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
),
MovieInfos AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.info_details, 'No Info') AS info_details,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = tm.movie_id AND mc.note IS NOT NULL) AS company_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfos mi ON tm.movie_id = mi.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
