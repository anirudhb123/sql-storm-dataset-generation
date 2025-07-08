
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title et
    INNER JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
MovieDetails AS (
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        CAST(COALESCE(mo.info, 'N/A') AS TEXT) AS movie_info,
        ci.note AS cast_note,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY ci.nr_order) AS cast_order
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_info mo ON mh.movie_id = mo.movie_id
    WHERE 
        mh.production_year IS NOT NULL
),
CompanyInfo AS (
    
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_info,
    md.cast_note,
    ci.company_names,
    ci.company_types,
    md.cast_order,
    COALESCE(NULLIF(md.cast_note, ''), 'No Role Info') AS cast_role_info,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic Movie' 
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern Movie' 
        ELSE 'Recent Movie' 
    END AS movie_category
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
WHERE 
    md.cast_order <= 5  
ORDER BY 
    md.production_year DESC, 
    md.title;
