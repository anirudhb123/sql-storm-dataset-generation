WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        m.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year, m.name
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.company_name,
    tm.cast_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT mk.keyword ORDER BY mk.keyword) AS keywords,
    COALESCE(AVG(ki.info_length), 0) AS avg_info_length
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year)
LEFT JOIN 
    movie_info mi ON mi.movie_id IN (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year)
LEFT JOIN 
    (SELECT 
        movie_id, 
        LENGTH(info) as info_length 
     FROM movie_info) ki ON ki.movie_id = tm.movie_title
GROUP BY 
    tm.movie_title, 
    tm.production_year, 
    tm.company_name, 
    tm.cast_count
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
