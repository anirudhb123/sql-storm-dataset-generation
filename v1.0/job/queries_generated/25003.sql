WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
KeywordMovieInfo AS (
    SELECT 
        m.title,
        km.keyword,
        mi.info
    FROM 
        movie_keyword mk
    JOIN 
        keyword km ON mk.keyword_id = km.id
    JOIN 
        title m ON mk.movie_id = m.id
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (1, 2)  -- Assuming 1 and 2 are relevant info_type_ids
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
CompleteMovieInfo AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_name,
        km.keyword,
        cd.company_name,
        cd.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordMovieInfo km ON rm.title = km.title
    LEFT JOIN 
        CompanyDetails cd ON rm.title = cd.movie_id
)
SELECT 
    title,
    production_year,
    actor_name,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies
FROM 
    CompleteMovieInfo
GROUP BY 
    title, production_year, actor_name
ORDER BY 
    production_year DESC, title;
