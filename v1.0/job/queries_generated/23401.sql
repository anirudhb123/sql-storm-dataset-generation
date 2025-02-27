WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_by_year,
        SUM(mk.keyword_id) OVER (PARTITION BY m.id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year IS NOT NULL AND 
        m.production_year > 1990
),
FilteredActors AS (
    SELECT 
        a.person_id, 
        a.name, 
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
RevisedCompanyData AS (
    SELECT 
        mc.movie_id,
        c.id AS company_id,
        c.name,
        ct.kind AS company_type,
        COALESCE(mci.info, 'No additional info') AS additional_info
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mci ON mc.movie_id = mci.movie_id AND mci.info_type_id = 1
)
SELECT 
    rm.title,
    rm.production_year,
    ra.name AS actor_name,
    rc.name AS company_name,
    rc.company_type,
    rc.additional_info,
    CASE 
        WHEN rm.keyword_count > 2 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    FilteredActors ra ON ci.person_id = ra.person_id
LEFT JOIN 
    RevisedCompanyData rc ON rm.movie_id = rc.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
WHERE 
    (rc.company_id IS NULL OR rc.company_type IS NOT NULL)
    AND rm.rank_by_year < 5
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ra.name, rc.name, rc.company_type, rc.additional_info
ORDER BY 
    rm.production_year DESC, rm.title;
