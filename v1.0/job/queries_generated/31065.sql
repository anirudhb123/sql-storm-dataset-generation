WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), 
CastInfoRanked AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
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
MovieKeywords AS (
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
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(ki.keywords, 'None') AS keywords,
    COALESCE(cd.company_name, 'Unknown') AS production_company,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    CASE 
        WHEN c.actor_rank IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS has_leading_actor
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords ki ON mh.movie_id = ki.movie_id
LEFT JOIN 
    CompanyDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    CastInfoRanked c ON mh.movie_id = c.movie_id AND c.actor_rank = 1
WHERE 
    mh.depth < 3
ORDER BY 
    mh.production_year DESC, mh.movie_title;
