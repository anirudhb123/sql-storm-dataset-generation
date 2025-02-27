WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TitleWithKeywords AS (
    SELECT 
        at.title,
        at.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        MovieKeywords mk ON at.id = mk.movie_id
)
SELECT 
    rw.title,
    rw.production_year,
    rw.cast_count,
    rw.rank,
    twk.keywords
FROM 
    RankedMovies rw
JOIN 
    TitleWithKeywords twk ON rw.title = twk.title AND rw.production_year = twk.production_year
WHERE 
    rw.rank <= 5
    AND rw.cast_count > 2
ORDER BY 
    rw.production_year DESC, 
    rw.rank ASC;
