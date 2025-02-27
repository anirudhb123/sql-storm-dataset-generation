WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(MAX(k.keyword), 'No Keywords') AS keywords,
        COUNT(DISTINCT cc.subject_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON cn.id = mc.company_id
    JOIN
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY
        mc.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        mt.keywords,
        mt.cast_count,
        ci.companies,
        ci.company_types,
        ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS rn
    FROM 
        MovieTitles mt
    LEFT JOIN 
        CompanyInfo ci ON ci.movie_id = mt.title_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.cast_count,
    dmi.keywords,
    dmi.companies,
    dmi.company_types
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.cast_count > 0
    AND dmi.rn <= 10
    AND dmi.production_year IS NOT NULL
ORDER BY 
    dmi.production_year DESC, dmi.title;
