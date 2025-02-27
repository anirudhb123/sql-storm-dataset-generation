WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY m.id) AS has_main_cast,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS movie_rank
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        RANK() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordDetails AS (
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
    rm.cast_count,
    CASE WHEN rm.has_main_cast = 1 THEN 'Yes' ELSE 'No' END AS has_main_cast,
    cd.company_name,
    cd.company_type,
    kd.keywords 
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id AND cd.company_rank = 1
LEFT JOIN 
    KeywordDetails kd ON rm.movie_id = kd.movie_id
WHERE 
    rm.movie_rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title ASC;
