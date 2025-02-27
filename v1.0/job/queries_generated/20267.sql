WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_list
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
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
)
SELECT 
    rm.title,
    rm.production_year,
    cd.total_cast,
    cd.cast_list,
    mk.keywords,
    (SELECT COUNT(DISTINCT mcc.company_id)
     FROM movie_companies mcc
     JOIN company_name cn ON mcc.company_id = cn.id
     WHERE mcc.movie_id = rm.movie_id AND cn.country_code IS NOT NULL) AS num_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year >= 2000 
    AND (cd.total_cast IS NULL OR cd.total_cast > 3)
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank ASC;
