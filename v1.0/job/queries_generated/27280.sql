WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS num_keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        num_companies, 
        num_keywords,
        ROW_NUMBER() OVER (ORDER BY num_companies DESC, num_keywords DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_companies,
    tm.num_keywords,
    ARRAY_AGG(DISTINCT ak.name) AS actors_names,
    ARRAY_AGG(DISTINCT cn.name) AS companies_names
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.num_companies, tm.num_keywords
ORDER BY 
    tm.rank;
