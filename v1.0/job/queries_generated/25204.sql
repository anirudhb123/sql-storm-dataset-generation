WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aliases
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        aliases,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(ak.name, ', ') AS aliases_combined,
    GROUP_CONCAT(DISTINCT pi.info ORDER BY pi.info_type_id) AS person_infos,
    STRING_AGG(DISTINCT co.name, ', ') AS companies_involved
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.movie_title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC;

This SQL query processes string data to benchmark performance within the provided schema. It selects the top movies based on the count of distinct actors, aggregates alias names for those movies, retrieves various person information, and lists involved companies, showcasing complex string processing and aggregation techniques.
