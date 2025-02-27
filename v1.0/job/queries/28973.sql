
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tk.keyword,
        COUNT(mi.info) AS info_count,
        RANK() OVER (ORDER BY COUNT(mi.info) DESC) AS rank
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords tk ON tm.movie_id = tk.movie_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tk.keyword
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    md.info_count
FROM 
    MovieDetails md
WHERE 
    md.rank <= 10
ORDER BY 
    md.movie_id, md.keyword;
