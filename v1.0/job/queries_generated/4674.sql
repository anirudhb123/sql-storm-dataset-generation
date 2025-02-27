WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(m.info, 'No Info Available') AS info,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.production_year = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON tm.production_year = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        title t ON t.production_year = tm.production_year
    GROUP BY 
        t.title, tm.production_year, m.info
)
SELECT 
    md.title,
    md.production_year,
    md.info,
    md.keywords,
    CASE 
        WHEN md.info IS NULL THEN 'Information Not Provided'
        ELSE md.info 
    END AS final_info,
    TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS') AS query_time
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
