WITH NameAggregates AS (
    SELECT 
        ak.person_id,
        COUNT(DISTINCT ak.name) AS name_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_names
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
),
MovieAggregates AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ci.note, '; ') AS cast_notes,
        AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year ELSE 0 END) AS avg_production_year
    FROM 
        movie_companies mc
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id 
    LEFT JOIN 
        aka_title mt ON mc.movie_id = mt.movie_id
    GROUP BY 
        mc.movie_id
),
FinalOutput AS (
    SELECT 
        na.person_id AS actor_id,
        na.all_names AS actor_names,
        ma.movie_id,
        ma.total_cast,
        ma.cast_notes,
        ma.avg_production_year
    FROM 
        NameAggregates na
    JOIN 
        MovieAggregates ma ON na.person_id = ma.movie_id
)
SELECT 
    fo.actor_id,
    fo.actor_names,
    fo.movie_id,
    fo.total_cast,
    fo.cast_notes,
    fo.avg_production_year
FROM 
    FinalOutput fo
WHERE 
    fo.total_cast > 5
ORDER BY 
    fo.avg_production_year DESC, 
    fo.total_cast DESC;
