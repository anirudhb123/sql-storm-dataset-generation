WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title,
        COUNT(c.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CastAggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_cast_count,
        MAX(case when ci.note IS NULL then 1 else 0 end) AS null_note_flag
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieTitles AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        k.phonetic_code
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT info_type_id) AS info_type_count,
        STRING_AGG(info, '; ') AS all_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    r.title AS movie_title,
    r.production_year,
    r.rank_title,
    COALESCE(c.unique_cast_count, 0) AS unique_cast_count,
    CASE 
        WHEN r.total_cast > 10 THEN 'Large Cast'
        WHEN r.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    mt.keyword,
    mt.phonetic_code,
    mi.info_type_count,
    mi.all_info,
    CASE 
        WHEN c.null_note_flag = 1 THEN 'Contains Null Note'
        ELSE 'No Null Note'
    END AS note_status
FROM 
    RankedMovies r
LEFT JOIN 
    CastAggregates c ON r.movie_id = c.movie_id
LEFT JOIN 
    MovieTitles mt ON r.movie_id = mt.movie_id
LEFT JOIN 
    MovieInfo mi ON r.movie_id = mi.movie_id
WHERE 
    r.rank_title <= 5
    AND (mi.all_info IS NULL OR mi.all_info LIKE '%Award%')
ORDER BY 
    r.production_year DESC, r.title;
