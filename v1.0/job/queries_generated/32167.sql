WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.imdb_id,
        t.episode_of_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.season_nr IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.imdb_id,
        m.episode_of_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.id
),
AggregateData AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MAX(t.production_year) AS latest_year
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        c.movie_id
),
FinalDetails AS (
    SELECT 
        mh.title,
        mh.production_year,
        ad.total_cast,
        ad.actor_names,
        mh.level,
        CASE 
            WHEN ad.total_cast IS NULL THEN 'No Cast'
            WHEN ad.latest_year < 2000 THEN 'Classic Movie'
            ELSE 'Modern Movie'
        END AS movie_category
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregateData ad ON mh.id = ad.movie_id
)
SELECT 
    fd.title,
    fd.production_year,
    fd.total_cast,
    fd.actor_names,
    fd.level,
    fd.movie_category
FROM 
    FinalDetails fd
ORDER BY 
    fd.production_year DESC, fd.level, fd.title;

This SQL query is structured to perform a performance benchmark across multiple tables from the Join Order Benchmark schema. It incorporates a recursive common table expression (CTE) to handle hierarchical data, aggregates cast information, and categorizes movies based on production year and the presence of cast members, demonstrating the use of outer joins, string aggregation, and complex conditional logic.
