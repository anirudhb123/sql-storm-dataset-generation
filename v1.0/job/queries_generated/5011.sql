WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
), 
TopCast AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
    HAVING 
        COUNT(*) > 1
), 
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
KeywordMovie AS (
    SELECT 
        mk.movie_id, 
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rt.title, 
    rt.production_year, 
    tc.actor_name, 
    tc.role_count, 
    mc.company_name, 
    mc.company_type, 
    km.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    TopCast tc ON rt.title_id = tc.movie_id
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    KeywordMovie km ON rt.title_id = km.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
