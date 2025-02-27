WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), HighRatingMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No Info') AS movie_description,
        km.keyword
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.production_year = mi.movie_id AND mi.info_type_id = 1
    LEFT JOIN 
        movie_keyword mk ON m.production_year = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        m.actor_count > 10
    ORDER BY 
        m.production_year DESC
)
SELECT 
    hm.title,
    hm.production_year,
    STRING_AGG(DISTINCT hm.keyword, ', ') AS keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = hm.production_year) AS complete_cast_count
FROM 
    HighRatingMovies hm
GROUP BY 
    hm.title, hm.production_year
HAVING 
    STRING_AGG(DISTINCT hm.keyword, ', ') IS NOT NULL 
ORDER BY 
    hm.production_year, complete_cast_count DESC;
