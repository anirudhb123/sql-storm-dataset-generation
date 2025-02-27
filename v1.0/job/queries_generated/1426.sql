WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
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
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(mi.info) AS general_info
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    mk.keywords,
    cd.company_names,
    mi.general_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    CompanyDetails cd ON rm.production_year = (SELECT t.production_year FROM aka_title t WHERE t.id = cd.movie_id)
LEFT JOIN 
    MovieInfo mi ON rm.production_year = (SELECT t.production_year FROM aka_title t WHERE t.id = mi.movie_id)
WHERE 
    rm.rank <= 5 AND (mk.keywords IS NOT NULL OR cd.company_names IS NOT NULL)
ORDER BY 
    rm.production_year, rm.cast_count DESC;
