WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(c.movie_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(m.cast_count, 0) AS cast_count,
        COALESCE((SELECT AVG(cast_count) FROM RankedMovies), 0) AS avg_cast_per_movie
    FROM 
        RankedMovies m
),
UniqueKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        ukc.keyword_count,
        cmc.company_count,
        CASE 
            WHEN md.cast_count IS NULL THEN 'No Cast'
            WHEN md.cast_count < md.avg_cast_per_movie THEN 'Below Average Cast'
            WHEN md.cast_count = md.avg_cast_per_movie THEN 'Average Cast'
            ELSE 'Above Average Cast'
        END AS casting_quality
    FROM 
        MovieDetails md
    LEFT JOIN 
        UniqueKeywordCount ukc ON md.id = ukc.movie_id
    LEFT JOIN 
        CompanyMovieCounts cmc ON md.id = cmc.movie_id
)

SELECT 
    title,
    production_year,
    CAST(cast_count AS INTEGER) AS total_cast,
    COALESCE(keyword_count, 0) AS total_keywords,
    COALESCE(company_count, 0) AS total_companies,
    casting_quality
FROM 
    FinalBenchmark
WHERE 
    COALESCE(cast_count, 0) > 0
ORDER BY 
    production_year DESC, total_cast DESC;
