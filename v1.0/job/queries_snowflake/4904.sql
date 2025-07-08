
WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
RankedMovies AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.keywords,
        c.companies,
        ROW_NUMBER() OVER (PARTITION BY mi.production_year ORDER BY mi.actor_count DESC) AS rank_within_year
    FROM 
        MovieInfo mi
    LEFT JOIN 
        CompanyInfo c ON mi.movie_id = c.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    CASE 
        WHEN rm.rank_within_year <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS rank_category,
    COALESCE(rm.keywords, ARRAY_CONSTRUCT()) AS keywords,
    COALESCE(rm.companies, ARRAY_CONSTRUCT()) AS companies
FROM 
    RankedMovies rm
WHERE 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.rank_within_year;
