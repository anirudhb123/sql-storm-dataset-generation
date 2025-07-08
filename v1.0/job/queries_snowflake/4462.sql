
WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    cd.company_name,
    cd.company_type,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = (SELECT at.id 
                                         FROM aka_title at 
                                         WHERE at.title = rm.movie_title 
                                         AND at.production_year = rm.production_year 
                                         LIMIT 1)
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = (SELECT ci.movie_id 
                                         FROM cast_info ci 
                                         WHERE ci.person_id IN (SELECT person_id 
                                                                FROM aka_name) 
                                         LIMIT 1)
WHERE 
    rm.rank = 1 AND 
    (cd.company_rank IS NULL OR cd.company_rank <= 2)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
