WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS full_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        rm.rank <= 5  -- Limit to top 5 movies from each production year
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.full_cast,
    ci.production_companies,
    ci.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
