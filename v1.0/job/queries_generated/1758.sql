WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT ak.name), 'Unknown') AS actors,
        COALESCE(GROUP_CONCAT(DISTINCT mk.keyword), 'No Keywords') AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    md.production_companies,
    CASE 
        WHEN md.production_companies = 0 THEN 'No Productions' 
        WHEN md.production_companies < 3 THEN 'Few Productions'
        ELSE 'Many Productions' 
    END AS production_category
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
    AND md.actors IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title ASC;
