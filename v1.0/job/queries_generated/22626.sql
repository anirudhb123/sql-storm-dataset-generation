WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MIN(t.production_year) AS first_movie_year,
        MAX(t.production_year) AS last_movie_year
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.person_id
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), 
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(ak.movie_count, 0) AS total_actors,
    COALESCE(ci.company_names, 'No Companies') AS companies_involved,
    COALESCE(ci.company_types, 'N/A') AS types_of_companies,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    CASE 
        WHEN ak.first_movie_year IS NOT NULL AND ak.last_movie_year IS NOT NULL THEN 
            ak.last_movie_year - ak.first_movie_year
        ELSE 
            NULL 
    END AS active_year_span
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStats ak ON rm.title_id = ak.person_id
LEFT JOIN 
    CompanyInfo ci ON rm.title_id = ci.movie_id
LEFT JOIN 
    KeywordCounts kc ON rm.title_id = kc.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
