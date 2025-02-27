WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        nm.name AS director_name,
        nm.gender,
        COALESCE(SUM(CASE WHEN kc.keyword = 'action' THEN 1 ELSE 0 END), 0) AS action_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name nm ON ci.person_id = nm.person_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, nm.name, nm.gender
),

LatestMovies AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.director_name,
        f.gender,
        f.action_count,
        ROW_NUMBER() OVER (PARTITION BY f.production_year ORDER BY f.action_count DESC) AS action_rank
    FROM 
        FilteredMovies f
)

SELECT 
    lm.movie_id,
    lm.title,
    lm.production_year,
    lm.director_name,
    lm.gender,
    lm.action_count
FROM 
    LatestMovies lm
WHERE 
    lm.action_rank <= 10 AND
    lm.production_year IS NOT NULL
ORDER BY 
    lm.production_year DESC, lm.action_count DESC;
