
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        rm.actor_rank <= 5 
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.kind_id
),
MoviesWithCompanies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        mwk.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        MoviesWithKeywords mwk
    JOIN 
        movie_companies mc ON mwk.movie_id = mc.movie_id
    GROUP BY 
        mwk.movie_id, mwk.title, mwk.production_year, mwk.kind_id
),
FinalBenchmark AS (
    SELECT 
        mwk.title,
        mwk.production_year,
        mwk.kind_id,
        mwk.keywords,
        COALESCE(mwc.company_count, 0) AS company_count,
        CASE 
            WHEN COALESCE(mwc.company_count, 0) > 0 THEN 'Produced'
            ELSE 'Independent'
        END AS production_status
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        MoviesWithCompanies mwc ON mwk.movie_id = mwc.movie_id
)
SELECT 
    title,
    production_year,
    kind_id,
    keywords,
    company_count,
    production_status
FROM 
    FinalBenchmark
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, company_count DESC;
