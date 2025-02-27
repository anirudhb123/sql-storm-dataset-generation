WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(DISTINCT kc.keyword) OVER (PARTITION BY m.id) AS keyword_count,
        AVG(CASE WHEN ci.person_role_id IS NULL THEN 0 ELSE 1 END) OVER (PARTITION BY m.id) AS cast_presence_ratio
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    WHERE 
        m.production_year IS NOT NULL
),

CompanyRank AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        ct.kind AS company_type,
        DENSE_RANK() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),

FinalOutput AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        rm.keyword_count,
        rm.cast_presence_ratio,
        cr.company_name,
        cr.company_type,
        CASE 
            WHEN rm.cast_presence_ratio < 1 THEN 'Missing Cast'
            WHEN rm.keyword_count = 0 THEN 'No Keywords'
            ELSE 'Complete'
        END AS movie_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyRank cr ON rm.movie_id = cr.movie_id AND cr.company_rank = 1
)

SELECT 
    movie_id,
    title,
    production_year,
    title_rank,
    keyword_count,
    cast_presence_ratio,
    company_name, 
    company_type,
    movie_status
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, title_rank
LIMIT 100;
