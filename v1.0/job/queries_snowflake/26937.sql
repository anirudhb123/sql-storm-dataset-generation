WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 5
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        pk.keyword AS popular_keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PopularKeywords pk ON rm.movie_id = pk.movie_id
    WHERE 
        rm.production_year > 2000
    ORDER BY 
        rm.cast_count DESC,
        rm.production_year DESC
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    COALESCE(fr.popular_keyword, 'No popular keyword') AS popular_keyword
FROM 
    FinalResults fr
LIMIT 100;
