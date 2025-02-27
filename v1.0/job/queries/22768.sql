WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND (t.production_year IS NOT NULL OR t.production_year > 2000) 
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(ci.person_id) AS cast_count,
        COALESCE(MAX(k.keyword), 'No Keyword') AS keyword_summary
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
KeywordCount AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.keyword_summary,
        DENSE_RANK() OVER (ORDER BY m.cast_count DESC) AS rank_by_cast
    FROM 
        MoviesWithCast m
), 
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.keyword_summary,
        COALESCE(ct.kind, 'Unknown Genre') AS genre,
        ci.note AS cast_note
    FROM 
        KeywordCount m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.keyword_summary,
    md.genre,
    md.cast_note,
    CASE 
        WHEN md.cast_count IS NULL THEN 'No Cast Available'
        WHEN md.cast_count > 5 THEN 'Large Cast'
        WHEN md.cast_count BETWEEN 1 AND 5 THEN 'Small Cast'
        ELSE 'No Cast Information'
    END AS cast_size_description,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.info ILIKE '%award%') THEN 'Award Winning'
        ELSE 'Not Awarded'
    END AS movie_status,
    (SELECT COUNT(*) FROM movie_link ml WHERE ml.movie_id = md.movie_id) AS related_links
FROM 
    MovieDetails md
WHERE 
    md.cast_count > 0
    AND md.production_year BETWEEN 2005 AND 2023
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;