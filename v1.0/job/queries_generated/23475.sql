WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(cm.kind) AS company_kind,
        AVG(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_ratio
    FROM 
        cast_info c
    LEFT JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    LEFT JOIN 
        company_type cm ON mc.company_type_id = cm.id
    LEFT JOIN 
        RankedMovies rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT CONCAT(COALESCE(mi.info, 'Unknown Info'), ' (' , it.info , ')'), '; ') AS infos
    FROM 
        movie_info mi
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        m.movie_id
),
FinalMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.actor_count,
        mc.company_kind,
        mi.infos,
        RANK() OVER (ORDER BY mc.actor_count DESC) AS actor_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.company_kind,
    COALESCE(fm.infos, 'No additional info') AS additional_info,
    CASE 
        WHEN fm.actor_rank IS NULL THEN 'No Actors'
        ELSE 'Rank: ' || fm.actor_rank
    END AS actor_rank_description
FROM 
    FinalMovies fm
WHERE 
    fm.production_year BETWEEN 1980 AND 2023
    AND (fm.actor_count > 0 OR fm.company_kind IS NOT NULL)
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC
LIMIT 100;
