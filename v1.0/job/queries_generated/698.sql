WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
), 
CompanyParticipation AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS movies_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        cc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cp.company_name, 'No Company') AS company_name,
    COALESCE(cp.movies_count, 0) AS movies_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    cc.total_cast,
    COALESCE(cc.cast_names, 'No Cast') AS cast_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyParticipation cp ON rm.movie_id = cp.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompleteCast cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.production_year BETWEEN 1990 AND 2020
ORDER BY 
    rm.production_year DESC, rm.title ASC;
