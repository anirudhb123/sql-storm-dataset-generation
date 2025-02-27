WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        NULL::integer AS parent_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mh.movie_id,
        mh.depth + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RoleStats AS (
    SELECT 
        ci.role_id,
        COUNT(ci.id) AS role_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_percentage
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
),
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        rk.kind AS role_kind,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        RoleStats rs ON rs.role_id = m.kind_id
    JOIN 
        kind_type rk ON m.kind_id = rk.id
    WHERE 
        m.production_year >= 2010 
        AND rs.role_count > 5
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COUNT(DISTINCT kw.id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        tm.role_kind IS NOT NULL
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.depth,
    fm.keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    FilteredMovies fm ON mh.movie_id = fm.movie_id
WHERE 
    mh.depth < 3
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    mh.title ASC;
