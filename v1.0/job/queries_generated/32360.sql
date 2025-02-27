WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY m.production_year DESC) AS rn
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
CastDetails AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order IS NOT NULL
    GROUP BY 
        m.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    COALESCE(mi.company_count, 0) AS company_count,
    COALESCE(cd.cast_count, 0) AS cast_count,
    mi.keywords,
    cd.cast_names,
    CASE 
        WHEN mi.production_year < 2000 THEN 'Classic'
        WHEN mi.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_category
FROM 
    MovieInfo mi
FULL OUTER JOIN 
    CastDetails cd ON mi.movie_id = cd.movie_id
WHERE 
    (mi.title ILIKE '%The%' OR cd.cast_count > 0)
ORDER BY 
    mi.production_year DESC NULLS LAST, 
    mi.title ASC;
