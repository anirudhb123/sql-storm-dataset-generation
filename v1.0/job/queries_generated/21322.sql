WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieInfoWithKeywords AS (
    SELECT 
        m.movie_id,
        m.info,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_info m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
NullHandledMovieCompanies AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
DistinctRoles AS (
    SELECT DISTINCT
        ci.role_id, 
        rt.role AS role_name 
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
FinalBenchmark AS (
    SELECT
        m.title,
        m.production_year,
        nk.company_name,
        dr.role_name,
        json_agg(k.keyword) AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        NullHandledMovieCompanies nk ON m.movie_id = nk.movie_id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        DistinctRoles dr ON ci.role_id = dr.role_id
    LEFT JOIN 
        MovieInfoWithKeywords kw ON m.movie_id = kw.movie_id AND kw.keyword_rank = 1
    WHERE
        m.year_rank <= 10 AND
        (m.production_year < 2000 OR nk.company_name IS NOT NULL) 
    GROUP BY 
        m.title, m.production_year, nk.company_name, dr.role_name
    HAVING 
        COUNT(DISTINCT dr.role_name) > 1 OR nk.company_type IS NOT NULL
)
SELECT 
    *,
    CASE 
        WHEN keywords IS NOT NULL THEN 'Active'
        ELSE 'Inactive' 
    END AS keyword_status,
    CASE 
        WHEN production_year >= 2000 THEN 'Modern'
        ELSE 'Classic' 
    END AS movie_period
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, title;
