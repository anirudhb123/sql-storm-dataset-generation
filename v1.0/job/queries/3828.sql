WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
DirectorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role = 'director'
    GROUP BY 
        c.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    dm.director_count,
    kc.keyword_count,
    COALESCE(kc.keyword_count, 0) AS adjusted_keyword_count,
    CASE 
        WHEN dm.director_count > 3 THEN 'Highly Directed'
        WHEN dm.director_count IS NULL THEN 'No Directors'
        ELSE 'Moderately Directed'
    END AS director_rating
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorMovies dm ON rm.title_id = dm.movie_id
LEFT JOIN 
    KeywordCount kc ON rm.title_id = kc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
