WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id
), MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.title_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON rm.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        aka_title ak ON rm.title_id = ak.movie_id
    GROUP BY 
        rm.title_id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.aka_names,
    md.company_names,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.cast_count DESC
LIMIT 10;
