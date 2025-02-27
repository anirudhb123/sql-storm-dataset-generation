WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) 
            OVER (PARTITION BY a.id), 0) AS avg_cast_size,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        a.id
),
TopRatedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        m.id
    HAVING 
        COUNT(DISTINCT mk.keyword) > 5
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.avg_cast_size,
        tr.total_keywords
    FROM 
        RankedMovies rm
    JOIN 
        TopRatedMovies tr ON rm.title = tr.title
    WHERE 
        rm.rank <= 10
)
SELECT 
    fr.title,
    fr.production_year,
    CASE 
        WHEN fr.avg_cast_size IS NOT NULL THEN fr.avg_cast_size
        ELSE 'No Cast info' 
    END AS avg_cast_size,
    COALESCE(fr.total_keywords, 0) AS total_keywords,
    (CASE 
        WHEN fr.total_keywords >= 10 THEN 'High'
        WHEN fr.total_keywords BETWEEN 5 AND 9 THEN 'Medium'
        ELSE 'Low'
    END) AS keyword_rating
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.avg_cast_size DESC;
