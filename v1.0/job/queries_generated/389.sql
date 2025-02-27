WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) as actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) as rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
HighActorCount AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        actor_count >= 5
),
CompanyMovies AS (
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
MoviesWithCompanies AS (
    SELECT 
        hm.title,
        hm.production_year,
        GROUP_CONCAT(DISTINCT cm.company_name) AS companies
    FROM 
        HighActorCount hm
    LEFT JOIN 
        CompanyMovies cm ON hm.title IN (SELECT t.title FROM aka_title t WHERE t.id = cm.movie_id)
    GROUP BY 
        hm.title, hm.production_year
),
FinalResult AS (
    SELECT 
        mwc.title,
        mwc.production_year,
        mwc.companies,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY mwc.title) as distinct_actors
    FROM 
        MoviesWithCompanies mwc
    LEFT JOIN 
        movie_keyword mk ON mwc.title IN (SELECT t.title FROM aka_title t WHERE t.id = mk.movie_id)
    LEFT JOIN 
        cast_info c ON mwc.title IN (SELECT t.title FROM aka_title t WHERE t.id = c.movie_id)
)
SELECT 
    title,
    production_year,
    companies,
    keyword,
    distinct_actors 
FROM 
    FinalResult
WHERE 
    production_year IS NOT NULL
ORDER BY 
    production_year DESC, distinct_actors DESC;
