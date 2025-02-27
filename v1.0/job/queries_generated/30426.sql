WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.id IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
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
ActorPerformance AS (
    SELECT 
        c.movie_id,
        a.name,
        COUNT(*) AS show_count,
        RANK() OVER (PARTITION BY a.name ORDER BY COUNT(*) DESC) AS rank_performance
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(k.keyword, 'No Keywords') AS keywords,
        COALESCE(CAST(m.production_year AS text), 'Unknown Year') AS production_year,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ap.name AS actor_name,
    ap.show_count,
    md.keywords,
    md.production_year AS movie_year,
    CASE 
        WHEN ap.rank_performance = 1 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_rank,
    COALESCE(cn.name, 'No Company') AS company_name
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorPerformance ap ON mh.movie_id = ap.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    MovieDetails md ON mh.movie_id = md.movie_id
WHERE 
    mh.level < 2
ORDER BY 
    mh.production_year DESC, 
    ap.show_count DESC, 
    mh.title ASC
LIMIT 100;
