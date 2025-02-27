WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS unique_actors
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS m_info,
        MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info = 'box office' THEN mi.info END) AS box_office
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.cast_count, 0) AS total_cast,
    COALESCE(cd.unique_actors, 'No actors') AS actors_list,
    COALESCE(mi.m_info, 'No information') AS additional_info,
    CASE 
        WHEN mi.budget IS NULL THEN 'Budget not available'
        ELSE mi.budget
    END AS available_budget,
    CASE 
        WHEN mi.box_office IS NULL THEN 'Box office not available'
        ELSE mi.box_office
    END AS box_office_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank_year <= 3
ORDER BY 
    rm.production_year DESC, rm.title;
