WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY co.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieKeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords,
        COUNT(DISTINCT k.id) AS unique_keywords_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cd.company_name, 'No Company') AS company_name,
    COALESCE(cd.company_type, 'Unknown Type') AS company_type,
    rm.cast_count,
    mk.keywords,
    mk.unique_keywords_count,
    CASE 
        WHEN rm.cast_count IS NULL THEN 'No Cast Info' 
        WHEN rm.cast_count > 10 THEN 'Large Cast' 
        ELSE 'Small Cast' 
    END AS cast_size_category,
    CASE 
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN '21st Century'
        WHEN rm.production_year < 2000 THEN 'Before 21st Century'
        ELSE 'Future Release'
    END AS release_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id AND cd.company_rank = 1
LEFT JOIN 
    MovieKeywordDetails mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.title_rank <= 5 
    AND (rm.production_year IS NOT NULL OR mk.unique_keywords_count IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
