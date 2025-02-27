WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        sub_mt.title,
        sub_mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title sub_mt ON ml.linked_movie_id = sub_mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(COALESCE(char.name, 'Unknown'), ' (', ct.kind, ')'), '; ') AS cast_details
    FROM 
        cast_info ci
    LEFT JOIN 
        char_name char ON ci.person_id = char.imdb_id
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id 
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        cf.total_cast,
        mk.keywords,
        CASE 
            WHEN mh.level > 1 THEN 'Part of a Series'
            ELSE 'Single Movie'
        END AS movie_type
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastInfoWithRoles cf ON mh.movie_id = cf.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)

SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.total_cast,
    f.keywords,
    f.movie_type,
    COALESCE(SUBSTRING(f.keywords FROM '.*(\[.*\]).*'), 'No Keywords') AS extracted_keywords
FROM 
    FilteredMovies f
WHERE 
    f.production_year >= 2000 
    AND (f.movie_type = 'Single Movie' OR f.total_cast > 5)
ORDER BY 
    f.production_year DESC, 
    f.total_cast DESC;
