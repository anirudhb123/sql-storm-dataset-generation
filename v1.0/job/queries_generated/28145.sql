WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        companies
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.companies,
    (SELECT 
        COUNT(DISTINCT ci.person_id)
     FROM 
        cast_info ci
     WHERE 
        ci.movie_id = tm.movie_id) AS total_cast,
    (SELECT 
        COUNT(DISTINCT pi.info) 
     FROM 
        movie_info mi
     JOIN 
        person_info pi ON mi.movie_id = tm.movie_id AND mi.info_type_id = pi.info_type_id) AS total_info
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    total_cast DESC;
