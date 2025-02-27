WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m 
    WHERE 
        m.production_year >= 2000 
    
    UNION ALL
    
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mv ON ml.linked_movie_id = mv.movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mv.production_year >= 2000
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_type
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MovieKeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc 
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cd.actor_name,
        cd.role_type,
        mki.keywords,
        mci.companies,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    LEFT JOIN 
        MovieKeywordInfo mki ON mh.movie_id = mki.movie_id
    LEFT JOIN 
        MovieCompanyInfo mci ON mh.movie_id = mci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    role_type,
    keywords,
    companies
FROM 
    RankedMovies
WHERE 
    (keywords IS NOT NULL AND companies IS NOT NULL)
    OR 
    (actor_name IS NULL AND production_year > 2010)
ORDER BY 
    production_year DESC, rank;
