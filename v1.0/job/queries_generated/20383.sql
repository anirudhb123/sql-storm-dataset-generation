WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = m.movie_id
    GROUP BY 
        m.movie_id, m.title
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        SUM(CASE WHEN ct.kind ILIKE '%Production%' THEN 1 ELSE 0 END) AS production_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
CombinedStats AS (
    SELECT 
        md.movie_id,
        md.title,
        md.cast_count,
        md.keyword_count,
        COALESCE(cs.company_count, 0) AS company_count,
        COALESCE(cs.production_count, 0) AS production_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyStats cs ON md.movie_id = cs.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    cs.cast_count,
    cs.keyword_count,
    cs.company_count,
    cs.production_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CombinedStats cs ON rm.title_id = cs.movie_id
WHERE 
    cs.cast_count > 0 OR cs.keyword_count > 0
ORDER BY 
    rm.production_year DESC, 
    cs.company_count DESC NULLS LAST, 
    cs.cast_count ASC NULLS FIRST
LIMIT 50;
