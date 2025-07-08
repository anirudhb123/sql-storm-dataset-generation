
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL OR c.note = 'featured'
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT mc.company_id) > 0
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ak.actor_name,
    ak.role,
    ak.nr_order,
    mkc.keyword_count,
    mci.company_count,
    mci.companies,
    CASE 
        WHEN mkc.keyword_count IS NULL THEN 'No keywords' 
        ELSE 'Has keywords' 
    END AS keyword_status,
    CASE 
        WHEN mci.company_count > 5 THEN 'Blockbuster'
        ELSE 'Indie'
    END AS movie_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ak ON rm.movie_id = ak.movie_id
LEFT JOIN 
    MovieKeywordCounts mkc ON rm.movie_id = mkc.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
WHERE 
    rm.production_year > 2000
    AND (mci.company_count IS NULL OR mci.companies LIKE '%Warner%')
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank, 
    ak.nr_order ASC
LIMIT 100;
