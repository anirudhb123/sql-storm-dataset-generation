WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
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
DetailedMovies AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(ci.cast_count, 0) AS cast_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.id = mk.movie_id
    LEFT JOIN 
        RankedMovies ci ON tm.title = ci.title AND tm.production_year = ci.production_year
)
SELECT 
    title,
    production_year,
    keywords,
    cast_count,
    CASE 
        WHEN cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_avail
FROM 
    DetailedMovies
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 10;

SELECT 
    DISTINCT ci.person_id,
    aa.name,
    COUNT(DISTINCT ac.movie_id) AS movies_participated
FROM 
    cast_info ac
JOIN 
    aka_name aa ON ac.person_id = aa.person_id
WHERE 
    ac.movie_id IN (SELECT movie_id FROM movie_info WHERE info LIKE '%Oscar%')
GROUP BY 
    ci.person_id, aa.name
HAVING 
    movies_participated > 3
ORDER BY 
    movies_participated DESC;
