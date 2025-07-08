
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        ka.name AS main_actor,
        MT.kind AS movie_type,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        aka_name ka ON c.person_id = ka.person_id
    LEFT JOIN
        kind_type MT ON t.kind_id = MT.id
    WHERE
        t.production_year IS NOT NULL
        AND ka.name IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.main_actor,
        rm.movie_type
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_year <= 5
),
MovieStatistics AS (
    SELECT 
        t.production_year,
        COUNT(t.title) AS total_movies,
        ARRAY_AGG(DISTINCT t.movie_type) AS unique_movie_types,
        MAX(LENGTH(t.title)) AS longest_title_length
    FROM 
        TopMovies t
    GROUP BY 
        t.production_year
),
CompanyStats AS (
    SELECT 
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        LISTAGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.production_year
),
FinalBenchmark AS (
    SELECT
        ms.production_year,
        ms.total_movies,
        ms.unique_movie_types,
        ms.longest_title_length,
        cs.total_companies,
        cs.company_names
    FROM 
        MovieStatistics ms
    LEFT JOIN 
        CompanyStats cs ON ms.production_year = cs.production_year
)

SELECT 
    fb.production_year,
    fb.total_movies,
    COALESCE(fb.unique_movie_types, ARRAY_CONSTRUCT()) AS unique_movie_types,
    fb.longest_title_length,
    COALESCE(fb.total_companies, 0) AS total_companies,
    COALESCE(fb.company_names, 'None') AS company_names
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC
LIMIT 10;
