WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = a.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
), 

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        title_rank,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
), 

PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
), 

KeywordRank AS (
    SELECT 
        movie_id,
        keyword,
        DENSE_RANK() OVER (PARTITION BY movie_id ORDER BY keyword_count DESC) AS keyword_rank
    FROM 
        PopularKeywords
)

SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(kr.keyword, 'No Keywords') AS top_keyword,
    tm.total_cast,
    CASE 
        WHEN tm.total_cast > 10 THEN 'Ensemble'
        WHEN tm.total_cast BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Minimal'
    END AS cast_category,
    CASE 
        WHEN kr.keyword IS NULL THEN 'No keyword available'
        ELSE 'Keyword found: ' || kr.keyword
    END AS detailed_keyword_info
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordRank kr ON tm.movie_title = (
        SELECT title FROM aka_title WHERE movie_id IN (
            SELECT movie_id FROM movie_keyword WHERE keyword_id IN (
                SELECT id FROM keyword WHERE keyword = kr.keyword
            )
        )
    ) 
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC, 
    tm.movie_title ASC;
