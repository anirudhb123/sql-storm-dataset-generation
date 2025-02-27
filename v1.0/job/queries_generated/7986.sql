WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        rm.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.company_names,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.cast_count DESC, 
    md.title;
