WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Start with root movies and their details
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        1 AS level
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL

    UNION ALL

    -- Recursive case: Find linked movies
    SELECT 
        linked_movie.id AS movie_id,
        linked_movie.title,
        linked_movie.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title linked_movie ON ml.linked_movie_id = linked_movie.id
),

MovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT ki.keyword) AS keywords
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.id) AS total_cast,
        STRING_AGG(DISTINCT COALESCE(a.name, 'Unknown'), ', ') AS actor_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),

MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mi.title,
    mi.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.actor_names, 'None') AS actor_names,
    COALESCE(mci.companies, 'None') AS companies,
    ARRAY_TO_STRING(mi.keywords, ', ') AS keywords,
    CASE 
        WHEN mi.production_year < 2000 THEN 'Classic'
        WHEN mi.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    MovieInfo mi
LEFT JOIN 
    CastDetails cd ON mi.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON mi.movie_id = mci.movie_id
ORDER BY 
    mi.production_year DESC, 
    mi.title;
