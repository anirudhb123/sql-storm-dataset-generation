WITH RankedTitles AS (
    SELECT 
        akn.person_id,
        akn.name AS actor_name,
        ttl.title AS movie_title,
        ttl.production_year,
        ROW_NUMBER() OVER (PARTITION BY akn.person_id ORDER BY ttl.production_year DESC) AS rn
    FROM 
        aka_name akn
    JOIN 
        cast_info ci ON akn.person_id = ci.person_id
    JOIN 
        aka_title ttl ON ci.movie_id = ttl.id
    WHERE 
        ttl.production_year IS NOT NULL
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        mc.note AS company_note
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),

KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    cd.company_name,
    cd.company_type,
    kd.keywords,
    COALESCE(cd.company_note, 'No notes available') AS company_notes
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyDetails cd ON rt.movie_title = cd.company_name
LEFT JOIN 
    KeywordDetails kd ON rt.movie_title = kd.movie_id
WHERE 
    rt.rn = 1 AND
    (cd.company_name IS NOT NULL OR kd.keywords IS NOT NULL)
ORDER BY 
    rt.production_year DESC, rt.actor_name ASC; 

