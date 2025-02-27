WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        ARRAY_AGG(DISTINCT c.name) AS cast_names, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
), RankedMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        cast_names, 
        keywords,
        rn,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rank_overall
    FROM 
        RecursiveMovieCTE
), CompanyInfoCTE AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types,
        (SELECT COUNT(*) 
         FROM movie_companies mcs 
         WHERE mcs.movie_id = mc.movie_id) AS num_companies
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
    rm.movie_id, 
    rm.movie_title, 
    rm.production_year, 
    rm.cast_names,
    rm.keywords,
    ci.company_names,
    ci.company_types,
    ci.num_companies,
    CASE 
        WHEN bm.movie_id IS NOT NULL THEN 'Has Benchmark'
        ELSE 'No Benchmark'
    END AS benchmark_status
FROM 
    RankedMovies rm
LEFT JOIN 
    (SELECT 
         movie_id 
     FROM 
         movie_info 
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'benchmark')) bm 
    ON rm.movie_id = bm.movie_id
LEFT JOIN 
    CompanyInfoCTE ci ON rm.movie_id = ci.movie_id
WHERE 
    (rm.rank_overall <= 10 OR ci.num_companies > 2) 
    AND rm.production_year BETWEEN 1990 AND 2020 
    AND rm.cast_names IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    ci.num_companies DESC;

