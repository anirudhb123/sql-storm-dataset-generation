
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title AS mt
    LEFT JOIN movie_companies AS mc ON mt.movie_id = mc.movie_id
    LEFT JOIN aka_name AS ak ON mt.id = ak.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_count,
        aka_names,
        ROW_NUMBER() OVER (ORDER BY company_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND production_year <= 2023
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.company_count,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = tm.movie_id) AS cast_count,
    (SELECT LISTAGG(res.info, ', ') WITHIN GROUP (ORDER BY res.info) FROM movie_info res WHERE res.movie_id = tm.movie_id AND res.info_type_id IN (SELECT id FROM info_type WHERE res.info = 'Summary')) AS movie_summary,
    (SELECT ARRAY_AGG(DISTINCT k.keyword) FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = tm.movie_id) AS related_keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
