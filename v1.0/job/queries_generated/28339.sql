WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rn
    FROM 
        aka_title ak
    JOIN 
        movie_keyword mk ON ak.movie_id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    JOIN 
        movie_companies mc ON ak.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        title m ON ak.movie_id = m.id
    GROUP BY 
        m.id, m.title, m.production_year
), DetailedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.aka_names,
        rm.company_names,
        pi.info 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info pi ON rm.movie_id = pi.movie_id 
    WHERE 
        rn <= 5  -- Get top 5 movies per production year
)
SELECT 
    dm.movie_id,
    dm.title,
    dm.production_year,
    dm.keyword_count,
    dm.aka_names,
    dm.company_names,
    pi.info_type_id,
    pi.info 
FROM 
    DetailedMovies dm
LEFT JOIN 
    person_info pi ON pi.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = dm.movie_id)
WHERE 
    dm.keyword_count > 0
ORDER BY 
    dm.production_year, dm.keyword_count DESC;

This SQL query utilizes Common Table Expressions (CTEs) to create a ranked list of movies based on the number of distinct keywords associated with them. It gathers additional information such as alternate names and company names related to each movie, and then retrieves detailed movie information along with any associated person information from the `person_info` table. The result is a comprehensive overview of the most keyword-rich movies, allowing for extensive benchmarking of string processing capabilities within the defined schema.
