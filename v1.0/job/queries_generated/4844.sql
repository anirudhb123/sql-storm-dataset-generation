WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_ratio,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        name p ON c.person_id = p.imdb_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
), YearlyStats AS (
    SELECT 
        production_year,
        SUM(cast_count) AS total_cast,
        AVG(female_ratio) AS avg_female_ratio
    FROM 
        RankedMovies
    GROUP BY 
        production_year
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    ys.total_cast,
    ys.avg_female_ratio,
    COALESCE(mk.all_keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
JOIN 
    YearlyStats ys ON rm.production_year = ys.production_year
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
