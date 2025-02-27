WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        rc.role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type rc ON rc.id = c.role_id
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
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    tt.title,
    tt.production_year,
    ai.name AS actor_name,
    cd.company_name,
    cd.company_type,
    mwk.keywords
FROM 
    RankedTitles tt
LEFT JOIN 
    cast_info ci ON ci.movie_id = tt.title_id
LEFT JOIN 
    ActorInfo ai ON ai.movie_id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = tt.title_id
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = tt.title_id
LEFT JOIN 
    MoviesWithKeywords mwk ON mwk.movie_id = tt.title_id
WHERE 
    tt.title_rank <= 5 AND
    (cd.company_name IS NOT NULL OR mwk.keywords IS NOT NULL)
ORDER BY 
    tt.production_year DESC, tt.title;
