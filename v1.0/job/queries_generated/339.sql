WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
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
        mt.id AS movie_id, 
        k.keyword 
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    AVG(CASE WHEN pi.info LIKE '%Oscar%' THEN 1 ELSE 0 END) AS oscar_indicator,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.title;
