
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COALESCE(kt.keyword, 'No Keywords') AS keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
),
CastingDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        MAX(CASE WHEN ci.kind IS NOT NULL THEN c.person_role_id END) AS lead_role
    FROM 
        cast_info c
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
CombinedStats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rd.total_cast,
        mc.company_count,
        rm.keyword,
        rm.title_rank
    FROM 
        RankedMovies rm
    JOIN 
        CastingDetails rd ON rm.movie_id = rd.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
)
SELECT 
    cs.title,
    cs.production_year,
    cs.total_cast,
    COALESCE(cs.company_count, 0) AS company_count,
    cs.keyword
FROM 
    CombinedStats cs
WHERE 
    cs.total_cast > 0
ORDER BY 
    cs.production_year DESC, cs.title_rank
LIMIT 100
OFFSET 0;
