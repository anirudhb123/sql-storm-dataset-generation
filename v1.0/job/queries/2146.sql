
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank_within_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mc.cast_count, 0) AS cast_count,
    COALESCE(mc.cast_names, '') AS cast_names,
    COALESCE(cd.company_names, '') AS company_names,
    CASE 
        WHEN COALESCE(mc.cast_count, 0) > 10 THEN 'Large Cast'
        WHEN COALESCE(mc.cast_count, 0) BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    COUNT(DISTINCT ki.keyword) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.title_id = mc.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.title_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    rm.rank_within_year = 1
    AND rm.production_year >= 2000
GROUP BY 
    rm.title, rm.production_year, mc.cast_count, mc.cast_names, cd.company_names
ORDER BY 
    rm.production_year DESC, mc.cast_count DESC;
