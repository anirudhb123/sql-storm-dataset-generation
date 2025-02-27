WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
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
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', rt.role)) AS actors
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year)
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
GROUP BY 
    md.title, md.production_year, md.keywords
ORDER BY 
    md.production_year DESC, md.title;
