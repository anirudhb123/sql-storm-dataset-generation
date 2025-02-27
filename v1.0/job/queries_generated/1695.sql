WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
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
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        k.keyword
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT mk.keyword) AS keywords
    FROM 
        topMovies tm
    LEFT JOIN 
        aka_title t ON t.title = tm.title AND t.production_year = tm.production_year
    LEFT JOIN 
        MovieKeywords mk ON t.id = mk.movie_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(NULLIF(md.keywords, ''), 'No keywords available') AS keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
