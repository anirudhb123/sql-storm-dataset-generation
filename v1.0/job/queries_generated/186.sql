WITH RecentMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COALESCE(MAX(c.nm_order), 0) AS max_order,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= (SELECT MAX(production_year) - 5 FROM aka_title)
    GROUP BY 
        t.id
),
CoActors AS (
    SELECT 
        ci.movie_id,
        a.name,
        COUNT(DISTINCT ci2.person_id) AS coactor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        cast_info ci2 ON ci.movie_id = ci2.movie_id AND ci.person_id <> ci2.person_id
    GROUP BY 
        ci.movie_id, a.name
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(DISTINCT cn.name) AS companies
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
    rm.max_order,
    rm.keyword_count,
    ca.name AS coactor_name, 
    ca.coactor_count,
    mc.companies
FROM 
    RecentMovies rm
LEFT JOIN 
    CoActors ca ON rm.movie_id = ca.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.keyword_count > 0
ORDER BY 
    rm.production_year DESC, 
    rm.max_order DESC, 
    ca.coactor_count DESC;
