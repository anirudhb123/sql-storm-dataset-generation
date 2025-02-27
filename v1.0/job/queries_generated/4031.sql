WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    rm.total_cast,
    cd.company_name,
    cd.company_type,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = cd.movie_id)
LEFT JOIN 
    MovieKeywords mk ON cd.movie_id = mk.movie_id
WHERE 
    rm.rank_by_cast <= 5 
    AND rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
