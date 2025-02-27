WITH MovieStats AS (
    SELECT 
        at.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN at.production_year IS NOT NULL THEN at.production_year ELSE 0 END) AS avg_production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.title
),
KeywordStats AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS total_keywords
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
),
MovieKeywordStats AS (
    SELECT 
        ms.movie_title,
        ms.total_cast,
        ms.avg_production_year,
        ms.cast_names,
        COALESCE(ks.total_keywords, 0) AS total_keywords
    FROM 
        MovieStats ms
    LEFT JOIN 
        KeywordStats ks ON ms.movie_title = (SELECT title FROM aka_title WHERE movie_id = ks.movie_id)
),
RankedMovies AS (
    SELECT 
        movie_title,
        total_cast,
        avg_production_year,
        total_keywords,
        RANK() OVER (ORDER BY total_cast DESC, avg_production_year ASC) AS cast_rank
    FROM 
        MovieKeywordStats
)
SELECT 
    movie_title,
    total_cast,
    avg_production_year,
    total_keywords,
    CASE 
        WHEN total_keywords > 10 THEN 'High Keywords'
        WHEN total_keywords BETWEEN 5 AND 10 THEN 'Medium Keywords'
        ELSE 'Low Keywords'
    END AS keyword_category
FROM 
    RankedMovies
WHERE 
    cast_rank <= 10
ORDER BY 
    total_cast DESC;
