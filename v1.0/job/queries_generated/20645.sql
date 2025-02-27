WITH RecursiveMovieLinks AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS link_depth
    FROM 
        movie_link ml

    UNION ALL

    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        rml.link_depth + 1
    FROM 
        movie_link ml
    JOIN 
        RecursiveMovieLinks rml ON ml.movie_id = rml.linked_movie_id
    WHERE 
        rml.link_depth < 5  -- Limit the depth to avoid infinite recursion
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieAttributes AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS average_info_length
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FinalBenchmark AS (
    SELECT 
        ma.title,
        ma.production_year,
        GROUP_CONCAT(DISTINCT cd.actor_name ORDER BY cd.actor_order) AS actor_list,
        ma.keyword_count,
        ma.average_info_length,
        COALESCE(ml.linked_movie_id, 0) AS linked_movie_id,
        CASE 
            WHEN ma.average_info_length IS NULL THEN 'No Info'
            ELSE 'Info Available'
        END AS info_status
    FROM 
        MovieAttributes ma
    LEFT JOIN 
        CastDetails cd ON ma.title = cd.movie_id
    LEFT OUTER JOIN 
        RecursiveMovieLinks ml ON ma.title = ml.movie_id
    GROUP BY 
        ma.title, ma.production_year, ma.keyword_count, ma.average_info_length, ml.linked_movie_id
    HAVING 
        ma.keyword_count > 5 OR (ma.average_info_length IS NULL AND COUNT(cd.actor_name) > 0)
)
SELECT 
    f.title,
    f.production_year,
    f.actor_list,
    f.keyword_count,
    f.average_info_length,
    f.linked_movie_id,
    f.info_status
FROM 
    FinalBenchmark f
ORDER BY 
    f.production_year DESC, 
    f.keyword_count DESC, 
    f.title;
