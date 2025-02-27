WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        tk.keywords,
        COALESCE(mi.info, 'No Info Available') AS movie_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords tk ON tm.title = tk.title
    LEFT JOIN 
        movie_info mi ON tm.production_year = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
)

SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.movie_info
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 10;
