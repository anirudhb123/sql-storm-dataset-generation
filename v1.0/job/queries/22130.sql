WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rank_per_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
FullCast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS full_cast,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        fc.full_cast,
        fc.total_cast,
        COALESCE(mi.info, 'No Synopsis Available') AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FullCast fc ON rm.title_id = fc.movie_id
    LEFT JOIN 
        movie_info mi ON rm.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'synopsis')
),
KeywordRetrieval AS (
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
FinalSelection AS (
    SELECT 
        md.*, 
        kr.keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordRetrieval kr ON md.title_id = kr.movie_id
)
SELECT 
    fs.title,
    fs.production_year,
    fs.full_cast,
    fs.total_cast,
    fs.movie_info,
    fs.keywords,
    CASE 
        WHEN fs.production_year IS NULL THEN 'Year Unknown'
        WHEN fs.production_year < 2000 THEN 'Classic'
        WHEN fs.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era_classification
FROM 
    FinalSelection fs
WHERE 
    fs.production_year IS NOT NULL
    AND fs.total_cast > 0
    AND fs.keywords LIKE '%' || COALESCE(NULLIF((SELECT keyword FROM keyword WHERE keyword LIKE 'thriller' LIMIT 1), ''), 'unknown') || '%'
ORDER BY 
    fs.production_year DESC, 
    fs.total_cast DESC;
