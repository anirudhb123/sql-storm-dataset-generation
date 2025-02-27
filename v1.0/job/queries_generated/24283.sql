WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
AggregatedInfo AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        SUM(CASE WHEN m.title ILIKE '%the%' THEN 1 ELSE 0 END) AS the_keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CompanyTypeStats AS (
    SELECT 
        mc.movie_id,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
),
FinalSelection AS (
    SELECT 
        rm.title_id,
        rm.movie_title,
        rm.production_year,
        ai.total_cast,
        ai.total_keywords,
        ai.the_keyword_count,
        ct.company_type,
        ct.company_count,
        RANK() OVER (PARTITION BY rm.production_year ORDER BY ai.total_cast DESC, ai.total_keywords DESC) AS popular_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        AggregatedInfo ai ON rm.title_id = ai.movie_id
    LEFT JOIN 
        CompanyTypeStats ct ON rm.title_id = ct.movie_id
    WHERE 
        ct.company_type IS NULL OR ct.company_count > 1
)

SELECT 
    fs.movie_title,
    fs.production_year,
    fs.total_cast,
    fs.total_keywords,
    fs.the_keyword_count,
    COALESCE(fs.company_type, 'Independent') AS company_type,
    fs.popular_rank
FROM 
    FinalSelection fs
WHERE 
    fs.popular_rank <= 5
ORDER BY 
    fs.production_year DESC,
    fs.total_cast DESC,
    fs.popular_rank ASC;
