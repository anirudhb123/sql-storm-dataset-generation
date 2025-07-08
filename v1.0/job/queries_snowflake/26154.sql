WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count
),
EnrichedMovies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.cast_count,
        mwk.keywords,
        ARRAY_AGG(DISTINCT ci.note) AS cast_notes
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        complete_cast cc ON mwk.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mwk.movie_id, mwk.title, mwk.production_year, mwk.cast_count, mwk.keywords
)
SELECT 
    em.movie_id,
    em.title,
    em.production_year,
    em.cast_count,
    em.keywords,
    em.cast_notes,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    EnrichedMovies em
LEFT JOIN 
    movie_companies mc ON em.movie_id = mc.movie_id
GROUP BY 
    em.movie_id, em.title, em.production_year, em.cast_count, em.keywords, em.cast_notes
ORDER BY 
    em.production_year DESC, em.cast_count DESC 
LIMIT 50;