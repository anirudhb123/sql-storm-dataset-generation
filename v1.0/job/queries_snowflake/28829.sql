WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        title ti ON t.movie_id = ti.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%') 
        AND t.production_year IS NOT NULL
),
AggregatedCasting AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT ak.name) AS unique_cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieWithMaxCast AS (
    SELECT 
        ac.movie_id,
        ac.total_cast,
        ac.unique_cast_names,
        rt.title,
        rt.production_year
    FROM 
        AggregatedCasting ac
    JOIN 
        RankedTitles rt ON ac.movie_id = rt.title_id
    WHERE 
        ac.total_cast = (SELECT MAX(total_cast) FROM AggregatedCasting)
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.total_cast,
    mw.unique_cast_names
FROM 
    MovieWithMaxCast mw
ORDER BY 
    mw.production_year DESC, mw.title ASC;
