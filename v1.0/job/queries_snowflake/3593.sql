
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
GenreKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT CONCAT(ak.name, ' as ', rt.role), ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_list
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.company_count, 0) AS total_companies,
    COALESCE(gk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.cast_list, 'No cast') AS cast
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyCount cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    GenreKeywords gk ON rm.movie_id = gk.movie_id
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    total_companies DESC;
