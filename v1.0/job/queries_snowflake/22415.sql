
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS role_rank,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        role_rank = 1
),
CompanyDetails AS (
    SELECT DISTINCT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
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
    trm.title,
    trm.production_year,
    trm.cast_count,
    cd.company_name,
    cd.company_type,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    TopRankedMovies trm
LEFT JOIN 
    CompanyDetails cd ON trm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON trm.movie_id = mk.movie_id
WHERE 
    trm.production_year > 2000
    AND (trm.cast_count > 10 OR cd.company_type IS NOT NULL)
ORDER BY 
    trm.production_year DESC,
    trm.title ASC;
