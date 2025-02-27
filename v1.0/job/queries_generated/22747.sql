WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

HighCastMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_within_year <= 5
),

MovieKeywords AS (
    SELECT 
        mt.movie_id,
        mk.keyword
    FROM 
        movie_keyword mt
    JOIN 
        keyword mk ON mt.keyword_id = mk.id
),

CompanyDetails AS (
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
)

SELECT 
    hm.title, 
    hm.production_year,
    ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
    ARRAY_AGG(DISTINCT cd.company_name) AS companies,
    (SELECT 
        COUNT(*) 
     FROM 
        person_info pi 
     WHERE 
        pi.person_id IN (SELECT person_id FROM cast_info ci WHERE ci.movie_id = hm.movie_id)
    ) AS total_person_info
FROM 
    HighCastMovies hm
LEFT JOIN 
    MovieKeywords mk ON hm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyDetails cd ON hm.movie_id = cd.movie_id
GROUP BY 
    hm.title, hm.production_year
HAVING 
    COUNT(DISTINCT cd.company_name) > 0
ORDER BY 
    hm.production_year DESC, 
    hm.title ASC;
