WITH MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_notes_flag,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS movie_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id 
    GROUP BY 
        mt.title, mt.production_year
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)

SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    COALESCE(cd.company_name, 'No Company') AS company_name,
    COALESCE(cd.company_count, 0) AS company_count,
    md.has_notes_flag,
    md.movie_rank
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_rank = cd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title;
