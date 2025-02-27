
WITH RecursiveMovieRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.nr_order IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mv.id AS movie_id,
        mv.title AS movie_title,
        mv.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN rg.kind = 'Horror' THEN 'Yes' ELSE 'No' END) AS is_horror,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_note_present
    FROM 
        aka_title mv
    LEFT JOIN 
        movie_keyword mk ON mv.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON mv.id = ci.movie_id
    LEFT JOIN 
        kind_type rg ON mv.kind_id = rg.id
    GROUP BY 
        mv.id, mv.title, mv.production_year
),
CorrelatedTypeCounts AS (
    SELECT 
        dt.movie_id,
        COUNT(DISTINCT cc.kind) AS unique_company_types
    FROM 
        movie_companies dc
    JOIN 
        company_type cc ON dc.company_type_id = cc.id
    JOIN 
        (SELECT DISTINCT movie_id FROM movie_companies) dt ON dc.movie_id = dt.movie_id
    GROUP BY 
        dt.movie_id
    HAVING 
        COUNT(DISTINCT cc.kind) > 2
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.keyword_count,
    md.is_horror,
    rc.role_name,
    ec.unique_company_types,
    COALESCE(md.avg_cast_note_present, 0) AS avg_cast_note_present
FROM 
    MovieDetails md
LEFT JOIN 
    RecursiveMovieRoles rc ON md.movie_id = rc.movie_id
LEFT JOIN 
    CorrelatedTypeCounts ec ON md.movie_id = ec.movie_id
WHERE 
    md.production_year >= 2000
    AND (md.is_horror = 'Yes' OR (md.keyword_count >= 5 AND md.production_year BETWEEN 2010 AND 2020))
ORDER BY 
    md.production_year DESC, 
    rc.role_order ASC NULLS LAST;
