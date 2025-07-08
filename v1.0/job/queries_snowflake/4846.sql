
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        a.id
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND a.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(ci.company_name, 'Unknown') AS company_name,
    ci.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.id
LEFT JOIN 
    CastDetails cd ON cd.movie_id = rm.id
LEFT JOIN 
    CompanyInfo ci ON ci.movie_id = rm.id
WHERE 
    rm.rank <= 5 
    AND rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC, rm.title;
