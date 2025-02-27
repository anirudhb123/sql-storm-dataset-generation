WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        a.title, a.production_year
),
MovieKeywords AS (
    SELECT
        a.id AS movie_id,
        k.keyword,
        RANK() OVER (PARTITION BY a.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    ARRAY_AGG(mk.keyword) FILTER (WHERE mk.keyword_rank <= 5) AS top_keywords,
    COALESCE(mi.info_details, 'No additional info') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_title = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.production_year = mi.movie_id
WHERE 
    rm.rank <= 10
GROUP BY 
    rm.movie_title, rm.production_year, rm.cast_count, mi.info_details
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
