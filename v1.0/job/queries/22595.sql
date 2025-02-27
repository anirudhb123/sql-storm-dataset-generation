WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(ci.id) OVER (PARTITION BY at.id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        at.production_year IS NOT NULL
),
AggregatedCasting AS (
    SELECT 
        bc.movie_id,
        COUNT(DISTINCT ci.person_role_id) AS distinct_roles
    FROM 
        cast_info ci
    JOIN 
        complete_cast bc ON ci.movie_id = bc.movie_id
    GROUP BY 
        bc.movie_id
),
MoviesWithInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        COALESCE(ai.info, 'No Info Available') AS additional_info,
        COALESCE(ac.distinct_roles, 0) AS unique_role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info ai ON rm.movie_id = ai.movie_id AND ai.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
    LEFT JOIN 
        AggregatedCasting ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.cast_count > 0
),
FinalMovies AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.production_year,
        mw.title_rank,
        mw.additional_info,
        mw.unique_role_count,
        nt.name AS top_billed_actor
    FROM 
        MoviesWithInfo mw
    LEFT JOIN 
        cast_info ci ON mw.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name nt ON ci.person_id = nt.person_id
    WHERE 
        ci.nr_order = 1 
        AND mw.production_year = (SELECT MAX(production_year) FROM RankedMovies)
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.title_rank,
    fm.additional_info,
    fm.unique_role_count,
    COALESCE(fm.top_billed_actor, 'Unknown Actor') AS top_billed_actor
FROM 
    FinalMovies fm
WHERE 
    fm.unique_role_count > 1
ORDER BY 
    fm.production_year DESC, 
    fm.title_rank
FETCH FIRST 10 ROWS ONLY;
