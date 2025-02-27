WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id DESC) AS rn,
        COUNT(DISTINCT c.id) OVER (PARTITION BY m.id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        cast_info c ON c.movie_id = m.id
    WHERE 
        (mc.note IS NULL OR mc.note != 'unknown')
        AND m.production_year IS NOT NULL
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),

MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        rm.cast_count > 0
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year
),

MovieDetails AS (
    SELECT 
        mwk.movie_id,
        mwk.movie_title,
        mwk.production_year,
        COALESCE(mi.info, 'No Info') AS movie_info,
        mwk.keywords,
        COALESCE(NULLIF(mwk.keywords, ''), 'No keywords') AS valid_keywords
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        movie_info mi ON mi.movie_id = mwk.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.movie_info,
    md.keywords,
    md.valid_keywords,
    CASE 
        WHEN md.production_year < 2000 THEN 'Old Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
        ELSE 'Recent Release'
    END AS classification,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY md.production_year) AS unique_cast_per_year,
    CASE 
        WHEN md.keywords IS NOT NULL THEN ARRAY_LENGTH(STRING_TO_ARRAY(md.keywords, ', '), 1)
        ELSE 0
    END AS keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON ci.movie_id = md.movie_id
WHERE 
    NOT EXISTS (
        SELECT 1 FROM aka_name an WHERE an.person_id = ci.person_id AND an.name IS NULL
    )
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC
LIMIT 100;
