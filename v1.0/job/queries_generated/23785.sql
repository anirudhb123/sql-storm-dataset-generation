WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
PeopleRoles AS (
    SELECT 
        p.id AS person_id,
        a.name AS actor_name,
        c.person_role_id,
        r.role,
        COUNT(*) OVER (PARTITION BY c.person_id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
AggregatedInfo AS (
    SELECT 
        m.movie_id,
        mq.keyword || CASE 
            WHEN mq.keyword IS NULL THEN ' (No Keyword)' 
            ELSE '' 
        END AS keyword_with_null_check,
        mi.info AS movie_information
    FROM 
        movie_keyword mq
    LEFT JOIN 
        movie_info mi ON mq.movie_id = mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    pr.actor_name,
    pr.role,
    mc.companies,
    mc.distinct_company_types,
    ai.keyword_with_null_check,
    ai.movie_information,
    CASE 
        WHEN rm.total_movies_in_year > 0 THEN (pr.role_count * 1.0 / rm.total_movies_in_year)
        ELSE NULL
    END AS role_fraction_in_year
FROM 
    RankedMovies rm
LEFT JOIN 
    PeopleRoles pr ON rm.movie_id = pr.person_id
LEFT JOIN 
    MovieCompanyDetails mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    AggregatedInfo ai ON rm.movie_id = ai.movie_id
WHERE 
    (rm.production_year BETWEEN 1990 AND 2023)
    AND (mc.distinct_company_types IS NULL OR mc.distinct_company_types > 2)
ORDER BY 
    rm.production_year DESC,
    rank_within_year ASC,
    pr.role_fraction_in_year DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
