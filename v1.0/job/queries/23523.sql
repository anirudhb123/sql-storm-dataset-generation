WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT co.name) AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),

ExtendedMovieDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.cast_count,
        ci.companies,
        ci.company_types,
        CASE 
            WHEN md.cast_count > 10 THEN 'Large Cast'
            WHEN md.cast_count > 0 AND md.cast_count <= 10 THEN 'Small Cast'
            ELSE 'No Cast'
        END AS cast_size,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank_by_cast_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyInfo ci ON md.movie_id = ci.movie_id
)

SELECT 
    emd.title,
    emd.production_year,
    emd.keywords,
    emd.companies,
    emd.company_types,
    emd.cast_size,
    emd.rank_by_cast_count
FROM 
    ExtendedMovieDetails emd
WHERE 
    emd.production_year IS NOT NULL
    AND emd.rank_by_cast_count <= 5
ORDER BY 
    emd.production_year DESC, 
    emd.cast_count DESC;