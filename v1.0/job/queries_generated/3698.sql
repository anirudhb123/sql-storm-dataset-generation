WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        at.title, at.production_year
), MovieKeywords AS (
    SELECT 
        at.title,
        k.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), CompanyDetails AS (
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
        cn.country_code IS NOT NULL
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.cast_count,
    mk.keyword AS movie_keyword,
    cd.company_name,
    cd.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.title
LEFT JOIN 
    CompanyDetails cd ON rm.title = (SELECT at.title FROM aka_title at WHERE at.id = cd.movie_id)
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
