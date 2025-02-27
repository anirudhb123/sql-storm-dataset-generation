WITH RankedMovies AS (
    SELECT 
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
KeywordsWithTitles AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MoviesWithMaxCast AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank = 1
),
MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        COALESCE(kt.keyword, 'No Keyword') AS keyword
    FROM 
        MoviesWithMaxCast mt
    LEFT JOIN 
        KeywordsWithTitles kt ON mt.title = kt.title
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    COUNT(DISTINCT ci.id) AS total_cast,
    AVG(CASE WHEN p.gender IS NULL THEN 0 ELSE 1 END) AS gender_ratio
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year)
LEFT JOIN 
    name p ON p.id = ci.person_id
GROUP BY 
    md.title, md.production_year, md.keyword
ORDER BY 
    md.production_year DESC, total_cast DESC
LIMIT 10;
