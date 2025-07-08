
WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
CompanyMovies AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code = 'USA'
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
    rm.cast_count,
    COALESCE(cm.company_name, 'Independent') AS production_company,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.title = (
        SELECT 
            at.title
        FROM 
            aka_title at 
        WHERE 
            at.id = cm.movie_id
        LIMIT 1
    )
LEFT JOIN 
    MovieKeywords mk ON rm.title = (
        SELECT 
            at.title
        FROM 
            aka_title at 
        WHERE 
            at.id = mk.movie_id
        LIMIT 1
    )
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
