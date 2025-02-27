WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year,
        AVG(mi.info_length) AS avg_info_length
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            LENGTH(info) AS info_length
        FROM 
            movie_info
        WHERE 
            note IS NULL OR note != 'Ignore'
    ) mi ON a.id = mi.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),

TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        avg_info_length
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 3
),

UniqueCharacters AS (
    SELECT 
        DISTINCT SUBSTRING(title FROM 1 FOR 1) AS first_char
    FROM 
        title
    WHERE 
        production_year BETWEEN 2000 AND 2020
),

MovieComps AS (
    SELECT 
        mc.movie_id, 
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.avg_info_length,
    mc.companies,
    mc.company_types,
    COALESCE(uc.first_char, 'N/A') AS first_char
FROM 
    TopMovies tm
LEFT JOIN 
    MovieComps mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
LEFT JOIN 
    UniqueCharacters uc ON LEFT(tm.title, 1) = uc.first_char
WHERE 
    tm.avg_info_length > 50
    OR EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1) AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%'))
ORDER BY 
    tm.production_year, tm.cast_count DESC;
