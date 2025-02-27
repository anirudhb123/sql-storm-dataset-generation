WITH RecursiveTitleStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        AVG(ci.nr_order) AS avg_order,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id
),
TopTitles AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY avg_order DESC) AS rank
    FROM 
        RecursiveTitleStats
)
SELECT 
    tt.title,
    tt.production_year,
    tt.total_cast,
    tt.avg_order,
    tt.roles_assigned,
    CASE 
        WHEN tt.roles_assigned > 0 THEN ROUND(CAST(tt.total_cast AS numeric) / tt.roles_assigned, 2)
        ELSE NULL 
    END AS cast_to_roles_ratio
FROM 
    TopTitles tt
WHERE 
    tt.rank <= 10
ORDER BY 
    tt.cast_to_roles_ratio DESC NULLS LAST;

-- Find movies with no keywords, and details on associated companies or the complete cast info
WITH MoviesWithoutKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(COUNT(mk.keyword_id), 0) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
    HAVING 
        COALESCE(COUNT(mk.keyword_id), 0) = 0
),
MovieCompanyInfo AS (
    SELECT 
        mwk.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        MoviesWithoutKeywords mwk
    LEFT JOIN 
        movie_companies mc ON mwk.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mwk.title, 
    mwk.keyword_count, 
    mci.company_name,
    mci.company_type
FROM 
    MoviesWithoutKeywords mwk
LEFT JOIN 
    MovieCompanyInfo mci ON mwk.movie_id = mci.movie_id
ORDER BY 
    mwk.title;

-- Investigate actors who have played roles in films without any credits
SELECT 
    ak.name AS actor_name, 
    COUNT(DISTINCT ci.movie_id) AS total_movies_without_credits
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
WHERE 
    ci.movie_id IS NULL 
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 0
ORDER BY 
    total_movies_without_credits DESC;
