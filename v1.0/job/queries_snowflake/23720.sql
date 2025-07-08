
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year, a.id
), 
TopMovies AS (
    SELECT 
        title, 
        production_year,
        movie_id
    FROM 
        RankedMovies 
    WHERE 
        rank_per_year <= 5
), 
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        COUNT(DISTINCT m.keyword_id) AS keyword_count,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword m ON tm.movie_id = m.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        tm.title, tm.production_year
), 
OverallStats AS (
    SELECT 
        COUNT(*) AS total_movies,
        AVG(keyword_count) AS avg_keywords,
        AVG(company_count) AS avg_companies
    FROM 
        MovieDetails
), 
FinalResult AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_names,
        md.keyword_count,
        md.company_count,
        os.total_movies,
        os.avg_keywords,
        os.avg_companies
    FROM 
        MovieDetails md
    CROSS JOIN 
        OverallStats os
)
SELECT 
    title, 
    production_year, 
    cast_names, 
    keyword_count,
    company_count,
    CASE
        WHEN keyword_count > avg_keywords THEN 'Above Average in Keywords'
        WHEN keyword_count < avg_keywords THEN 'Below Average in Keywords'
        ELSE 'Average in Keywords'
    END AS keyword_status,
    CASE 
        WHEN company_count > avg_companies THEN 'Above Average in Companies'
        WHEN company_count < avg_companies THEN 'Below Average in Companies'
        ELSE 'Average in Companies'
    END AS company_status
FROM 
    FinalResult
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, 
    keyword_count DESC;
