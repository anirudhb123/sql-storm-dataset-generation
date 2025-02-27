WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(CASE WHEN cc.role_id IS NOT NULL THEN 1 END) AS count_actors
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info cc ON at.id = cc.movie_id
    GROUP BY 
        at.id
), ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(DISTINCT cw.id) AS number_of_casts,
        AVG(DATEDIFF(NOW(), pi.info)) AS avg_days_since_last_movie
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        pi.info_type_id IS NULL OR pi.info_type_id in (SELECT id FROM info_type WHERE info='Last Move')
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(DISTINCT cw.id) > 0
), MovieCompanies AS (
    SELECT 
        DISTINCT mt.movie_id, 
        cn.name as company_name, 
        ct.kind as company_type
    FROM 
        movie_companies mt
    JOIN 
        company_name cn ON mt.company_id = cn.id
    JOIN 
        company_type ct ON mt.company_type_id = ct.id
    WHERE 
        cn.name IS NOT NULL
), MovieKeywordCounts AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title, 
    rm.production_year, 
    rm.title_rank,
    COALESCE(ad.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(mc.company_name, 'No Company') AS company_name,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    rm.count_actors,
    (CASE 
        WHEN rm.count_actors > 5 THEN 'Ensemble Cast'
        WHEN rm.count_actors BETWEEN 2 AND 5 THEN 'Small Cast'
        ELSE 'Solo Movie'
    END) AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.title = ad.actor_name
LEFT JOIN 
    MovieCompanies mc ON rm.title = (SELECT title FROM aka_title WHERE id = rm.movie_id) 
LEFT JOIN 
    MovieKeywordCounts mk ON rm.id = mk.movie_id
WHERE 
    rm.production_year >= 2000 
    AND rm.title_rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title ASC
LIMIT 100;

