WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
FilteredActors AS (
    SELECT 
        p.person_id,
        p.info,
        ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY pi.info_type_id) AS info_rank
    FROM 
        person_info pi
    JOIN 
        aka_name p ON pi.person_id = p.person_id
    WHERE 
        pi.info LIKE '%Academy%' OR pi.info LIKE '%Golden Globe%'
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    COALESCE(fc.person_id, 'No Info') AS top_actor_id,
    COALESCE(fc.info, 'No Additional Info') AS actor_info,
    mci.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredActors fc ON rm.rank = 1 AND fc.info_rank = 1
LEFT JOIN 
    MovieCompanyInfo mci ON rm.id = mci.movie_id
WHERE 
    rm.production_year >= 2000 AND rm.actor_count > 5
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
