
WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        COALESCE(SUM(CASE WHEN mi.info = 'Award' THEN 1 ELSE 0 END), 0) AS award_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, k.keyword
),

KindDistribution AS (
    SELECT 
        kt.kind AS kind_name,
        COUNT(md.movie_id) AS movie_count
    FROM 
        MovieDetails md
    JOIN 
        kind_type kt ON md.kind_id = kt.id
    GROUP BY 
        kt.kind
)

SELECT 
    md.movie_title,
    md.production_year,
    ARRAY_TO_STRING(md.cast_names, ', ') AS cast_list,
    md.movie_keyword,
    kd.kind_name,
    kd.movie_count,
    md.award_count
FROM 
    MovieDetails md
LEFT JOIN 
    KindDistribution kd ON md.kind_id = (
        SELECT id FROM kind_type WHERE kind = kd.kind_name LIMIT 1
    )
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
