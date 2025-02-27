WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
ActorMovies AS (
    SELECT 
        ka.person_id,
        kg.keyword,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        MAX(mi.info) AS most_common_info,
        COUNT(DISTINCT CASE WHEN co.info_type_id = 1 THEN mi.info END) AS internal_info_count -- Assuming some ID represents 'internal' info
    FROM 
        cast_info ci
    JOIN aka_name ka ON ci.person_id = ka.person_id
    JOIN movie_info mi ON ci.movie_id = mi.movie_id
    JOIN keyword kg ON mi.info LIKE CONCAT('%', kg.keyword, '%')
    LEFT JOIN movie_info_idx co ON mi.movie_id = co.movie_id
    GROUP BY 
        ka.person_id, kg.keyword
),
FilteredActors AS (
    SELECT 
        am.person_id,
        am.keyword,
        am.movie_count,
        am.most_common_info,
        ROW_NUMBER() OVER (ORDER BY am.movie_count DESC) AS rank
    FROM 
        ActorMovies am
    WHERE 
        am.movie_count > 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.country_code) AS country_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    fa.person_id,
    fa.keyword,
    fa.movie_count,
    fa.most_common_info,
    mc.country_count,
    mc.company_names
FROM 
    RankedMovies r
LEFT JOIN 
    FilteredActors fa ON fa.rank <= 10
LEFT JOIN 
    MovieCompanies mc ON r.movie_id = mc.movie_id
WHERE 
    (fa.movie_count IS NOT NULL OR mc.country_count IS NULL) -- showcasing NULL logic
ORDER BY 
    r.production_year DESC, 
    r.title ASC;

