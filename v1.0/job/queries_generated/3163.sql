WITH MovieStatistics AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        AVG(CASE WHEN i.info_type_id IS NOT NULL THEN 1 ELSE 0 END) * 100 AS info_percentage
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info i ON a.id = i.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.title, a.production_year
), RankedMovies AS (
    SELECT 
        title,
        production_year,
        total_cast,
        total_keywords,
        info_percentage,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, total_keywords DESC) AS rank
    FROM 
        MovieStatistics
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.total_keywords,
    rm.info_percentage,
    CASE 
        WHEN rm.rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS rank_category
FROM 
    RankedMovies rm
WHERE 
    rm.info_percentage IS NOT NULL
ORDER BY 
    rm.rank;
