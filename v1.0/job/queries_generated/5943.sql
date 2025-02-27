WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), HighCastMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
), MovieDetails AS (
    SELECT 
        hcm.movie_id,
        hcm.title,
        hcm.production_year,
        mi.info AS movie_info,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        HighCastMovies hcm
    LEFT JOIN 
        movie_info mi ON hcm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mw ON hcm.movie_id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        hcm.movie_id, hcm.title, hcm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_info,
    md.keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 10;
