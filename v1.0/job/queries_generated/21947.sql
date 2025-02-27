WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title ASC) AS overall_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
DistinctAkaNames AS (
    SELECT 
        a.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.name) AS name_rank
    FROM 
        aka_name AS a
    WHERE 
        a.name IS NOT NULL
),
MovieCompanyRoles AS (
    SELECT 
        mc.movie_id,
        c.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_type AS c ON mc.company_type_id = c.id
    GROUP BY 
        mc.movie_id, c.kind
),
FilteredCastInfo AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.person_role_id,
        CASE 
            WHEN ci.note IS NOT NULL THEN ci.note 
            ELSE 'No Note' 
        END AS role_note
    FROM 
        cast_info AS ci
    WHERE 
        ci.nr_order IS NOT NULL
),
MovieWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id
)
SELECT 
    rm.title,
    rm.production_year,
    dc.person_id,
    dc.name,
    r.role_note,
    mck.company_type,
    mck.total_companies,
    mwk.keywords,
    CASE 
        WHEN mck.total_companies > 5 THEN 'Major Production'
        WHEN mck.total_companies BETWEEN 1 AND 5 THEN 'Independent'
        ELSE 'No Companies'
    END AS company_status
FROM 
    RankedMovies AS rm
JOIN 
    FilteredCastInfo AS r ON rm.movie_id = r.movie_id
JOIN 
    DistinctAkaNames AS dc ON r.person_id = dc.person_id AND dc.name_rank = 1
LEFT JOIN 
    MovieCompanyRoles AS mck ON rm.movie_id = mck.movie_id
LEFT JOIN 
    MovieWithKeywords AS mwk ON rm.movie_id = mwk.movie_id
WHERE 
    rm.year_rank <= 10
    AND (mck.total_companies IS NULL OR mck.total_companies > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC, 
    dc.name ASC;
