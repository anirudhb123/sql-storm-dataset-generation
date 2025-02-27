WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%') 
        AND t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.cast_count, 0) AS cast_count,
    COALESCE(cd.cast_names, 'No cast available') AS cast_names,
    COALESCE(cc.company_name, 'No company available') AS company_name,
    COALESCE(cc.company_type, 'Unknown') AS company_type,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN 'Keywords found'
        ELSE 'No keywords found'
    END AS keyword_status,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic movie'
        ELSE 'Modern movie'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyDetails cc ON rm.movie_id = cc.movie_id AND cc.company_rank = 1
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.rank;
