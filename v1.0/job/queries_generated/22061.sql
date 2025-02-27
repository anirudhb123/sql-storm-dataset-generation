WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY a.id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.movie_id = mc.movie_id
    WHERE 
        a.production_year IS NOT NULL
), 
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        name cn ON ci.person_id = cn.imdb_id
    GROUP BY 
        ci.movie_id
),
KeywordAggregation AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'MPAA' THEN mi.info END) AS mpaa_rating,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info END) AS budget
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.title_rank,
    COALESCE(cd.cast_member_count, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_members,
    COALESCE(ka.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(mi.mpaa_rating, 'Not Rated') AS mpaa_rating,
    COALESCE(mi.budget, 'Unknown') AS budget,
    CASE 
        WHEN rm.company_count = 0 THEN 'Independent Film'
        WHEN rm.company_count BETWEEN 1 AND 3 THEN 'Small Production'
        ELSE 'Major Production'
    END AS production_scale
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    KeywordAggregation ka ON rm.movie_id = ka.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    (rm.production_year >= 2000 AND rm.production_year < 2023)
    AND (rm.title_rank < 10 OR rm.company_count > 5)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
