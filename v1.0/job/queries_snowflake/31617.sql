
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalMovieReport AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.level,
        md.cast_count,
        md.cast_names,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        MovieKeywords mk ON md.movie_id = mk.movie_id
)
SELECT 
    fmr.movie_id,
    fmr.title,
    fmr.production_year,
    fmr.level,
    fmr.cast_count,
    fmr.cast_names,
    fmr.keywords,
    ROW_NUMBER() OVER (PARTITION BY fmr.level ORDER BY fmr.production_year) AS ranked_by_year,
    CASE 
        WHEN fmr.production_year IS NULL THEN 'Unknown Year'
        WHEN fmr.production_year < 2000 THEN 'Classic'
        WHEN fmr.production_year BETWEEN 2000 AND 2010 THEN 'Recent'
        ELSE 'Modern'
    END AS movie_era
FROM 
    FinalMovieReport fmr
WHERE 
    fmr.cast_count > 0
ORDER BY 
    fmr.level, fmr.production_year;
