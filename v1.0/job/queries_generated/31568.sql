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
        c.movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        complete_cast c
    JOIN 
        aka_title m ON c.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON c.movie_id = mh.movie_id
),
AggregatedRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS count_persons
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
KeywordSummary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ar.count_persons, 0) AS total_roles,
        ks.keyword_list
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregatedRoles ar ON mh.movie_id = ar.movie_id
    LEFT JOIN 
        KeywordSummary ks ON mh.movie_id = ks.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_roles,
    md.keyword_list,
    RANK() OVER (ORDER BY md.total_roles DESC) AS rank_by_roles,
    CASE 
        WHEN md.total_roles > 10 THEN 'High'
        WHEN md.total_roles BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS role_density
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.total_roles DESC;
