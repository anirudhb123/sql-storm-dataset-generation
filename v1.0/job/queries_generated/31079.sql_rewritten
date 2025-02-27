WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(t.production_year, 0) AS production_year,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(t.production_year, 0) AS production_year,
        mh.level + 1
    FROM title t
    JOIN MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(k.keywords, 'None') AS keywords,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'Unknown') AS cast_names,
    COALESCE(c.company_count, 0) AS company_count,
    COALESCE(c.companies, 'Independent') AS companies,
    mh.level
FROM MovieHierarchy mh
LEFT JOIN MovieKeywords k ON mh.movie_id = k.movie_id
LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN CompanyDetails c ON mh.movie_id = c.movie_id
WHERE 
    mh.production_year >= 2000 
    AND (c.company_count > 2 OR c.companies LIKE '%Sony%')
ORDER BY mh.production_year DESC, mh.level ASC, mh.title;