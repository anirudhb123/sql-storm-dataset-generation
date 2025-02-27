WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actors,
        COALESCE(MIN(mk.keyword), 'No Keywords') AS keyword,
        COALESCE(MAX(mi.info), 'No Info') AS additional_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        movie_info mi ON tm.title = (SELECT title FROM aka_title WHERE id = mi.movie_id)
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.keyword,
    md.additional_info,
    COALESCE(cn.name, 'Unknown Company') AS company_name
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    md.production_year BETWEEN 1990 AND 2020
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
