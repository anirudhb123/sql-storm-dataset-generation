WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
),
DetailedMovieInfo AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.title = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year, tm.cast_count
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.cast_count,
    COALESCE(NULLIF(dmi.company_names[1], ''), 'Unknown Company') AS primary_company,
    COALESCE(ARRAY_LENGTH(dmi.keywords, 1), 0) AS keyword_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = dmi.title LIMIT 1) AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')) AS summary_info_count
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.production_year >= 2000
ORDER BY 
    dmi.production_year DESC, dmi.cast_count DESC;
