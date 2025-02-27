WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(c.id) DESC) AS rank,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.id = c.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mi.info, 'No Info') AS movie_info,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.movie_info,
        DISTINCT_STRING_AGG(kw.keyword) AS related_keywords,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = md.movie_id) AS company_count,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = md.movie_id AND cc.status_id = 1) AS completed_cast_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        LATERAL (
            SELECT 
                k.keyword 
            FROM 
                movie_keyword mk 
            JOIN 
                keyword k ON mk.keyword_id = k.id 
            WHERE 
                mk.movie_id = md.movie_id
        ) kw ON TRUE
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.movie_info
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.movie_info,
    COALESCE(fo.related_keywords, 'No related keywords') AS related_keywords,
    fo.company_count,
    fo.completed_cast_count
FROM 
    FinalOutput fo
WHERE 
    fo.company_count > 0
ORDER BY 
    fo.production_year DESC, 
    fo.title;
