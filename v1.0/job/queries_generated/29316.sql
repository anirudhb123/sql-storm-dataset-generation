WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        COALESCE(SUM(mi.info LIKE '%critically acclaimed%'), 0) AS acclaimed_count,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id in (SELECT id FROM info_type WHERE info LIKE '%critic%')
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.acclaimed_count,
        rm.cast_count,
        RANK() OVER (PARTITION BY rm.keyword ORDER BY rm.acclaimed_count DESC, rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
)

SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.acclaimed_count,
    tm.cast_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.keyword, tm.acclaimed_count DESC, tm.cast_count DESC;
