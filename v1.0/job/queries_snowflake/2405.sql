WITH MovieCounts AS (
    SELECT 
        a.title AS movie_title, 
        COUNT(DISTINCT c.person_id) AS cast_count, 
        AVG(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS has_keyword
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title
), 
RankedMovies AS (
    SELECT 
        mc.movie_title, 
        mc.cast_count, 
        mc.has_keyword,
        RANK() OVER (ORDER BY mc.cast_count DESC) AS cast_rank
    FROM 
        MovieCounts mc
    WHERE 
        mc.cast_count > 0
)

SELECT 
    rm.movie_title, 
    rm.cast_count, 
    CASE 
        WHEN rm.has_keyword > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS keyword_present,
    LAG(rm.cast_count, 1, 0) OVER (ORDER BY rm.cast_rank) AS previous_cast_count
FROM 
    RankedMovies rm
WHERE 
    rm.cast_rank <= 10
ORDER BY 
    rm.cast_rank;
