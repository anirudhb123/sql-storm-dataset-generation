WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 10
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        pk.keyword
    FROM 
        RankedMovies rm
    JOIN 
        PopularKeywords pk ON rm.movie_id = pk.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keyword
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.title;
