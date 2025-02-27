
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),

HighCastMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 10
)

SELECT 
    hcm.movie_id,
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    hcm.aka_names,
    hcm.keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(mo.info_type_id) AS average_info_type
FROM 
    HighCastMovies hcm
LEFT JOIN 
    movie_companies mc ON hcm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mo ON hcm.movie_id = mo.movie_id
GROUP BY 
    hcm.movie_id, hcm.title, hcm.production_year, hcm.cast_count, hcm.aka_names, hcm.keywords
ORDER BY 
    hcm.cast_count DESC, hcm.production_year DESC;
