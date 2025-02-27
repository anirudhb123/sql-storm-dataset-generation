WITH RECURSIVE FilmHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        fh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        FilmHierarchy fh ON ml.movie_id = fh.movie_id
),

RoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

TopRoles AS (
    SELECT 
        m.id AS movie_id,
        SUM(rc.role_count) FILTER (WHERE rc.role_count > 1) AS high_role_count
    FROM 
        aka_title m
    LEFT JOIN 
        RoleCounts rc ON m.id = rc.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
    HAVING 
        high_role_count IS NOT NULL
),

MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)

SELECT 
    fh.movie_id,
    fh.title,
    fh.production_year,
    md.cast_names,
    md.company_count,
    t.high_role_count
FROM 
    FilmHierarchy fh
LEFT JOIN 
    MovieDetails md ON fh.movie_id = md.movie_id
LEFT JOIN 
    TopRoles t ON fh.movie_id = t.movie_id
WHERE 
    md.company_count > 0 AND 
    (t.high_role_count IS NULL OR t.high_role_count > 2)
ORDER BY 
    fh.production_year DESC, 
    fh.depth,
    t.high_role_count DESC NULLS LAST;
