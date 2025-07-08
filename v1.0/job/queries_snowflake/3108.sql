
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(DISTINCT c.person_id) 
     FROM cast_info c 
     WHERE c.movie_id = rm.movie_id) AS total_cast,
    CASE 
        WHEN rm.rank_per_year = 1 THEN 'Top Movie of the Year'
        WHEN rm.rank_per_year <= 5 THEN 'Top 5 Movie of the Year'
        ELSE 'Regular Movie'
    END AS movie_status
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year >= 2000 AND rm.production_year <= 2023
ORDER BY 
    rm.production_year DESC, 
    rm.rank_per_year;
