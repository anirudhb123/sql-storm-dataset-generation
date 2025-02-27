WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth,
        mt.production_year,
        NULL::text AS parent_movie_title
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        mh.depth + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    INNER JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),

TitleKeywords AS (
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
    COALESCE(cd.total_cast, 0) AS total_cast_members,
    COALESCE(cd.cast_names, 'No cast information') AS cast_members,
    COALESCE(tk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN mh.depth > 1 THEN 'Episode'
        ELSE 'Feature'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    TitleKeywords tk ON mh.movie_id = tk.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, mh.movie_title;
