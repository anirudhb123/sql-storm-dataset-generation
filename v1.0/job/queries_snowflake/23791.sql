SQL
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsInfo AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS movie_count
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
CompanyDetails AS (
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
)

SELECT 
    rt.title, 
    rt.production_year,
    ai.actor_name, 
    ai.movie_count,
    kw.keywords,
    cd.company_name,
    cd.company_type
FROM 
    RankedTitles rt
JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
JOIN 
    ActorsInfo ai ON cc.subject_id = ai.person_id
LEFT JOIN 
    MoviesWithKeywords kw ON rt.title_id = kw.movie_id
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
WHERE 
    rt.rn <= 5
AND 
    (rt.production_year = 2022 OR cd.company_type IS NULL)
ORDER BY 
    rt.production_year DESC, 
    ai.movie_count DESC, 
    rt.title;
