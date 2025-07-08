
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank,
        COALESCE(SUM(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END), 0) AS lead_actors_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies_involved
    FROM aka_title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
), 
Summary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        rm.lead_actors_count,
        CASE 
            WHEN rm.lead_actors_count > 5 THEN 'Blockbuster'
            WHEN rm.production_year < 2000 THEN 'Classic'
            ELSE 'Average'
        END AS movie_category
    FROM RankedMovies rm
    WHERE rm.rank <= 10
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    sm.movie_id,
    sm.title,
    sm.production_year,
    sm.movie_category,
    km.keywords,
    COALESCE(sm.lead_actors_count, 0) AS lead_actors_count,
    CASE 
        WHEN sm.production_year >= 2020 THEN 'Recent Release'
        ELSE 'Older Release'
    END AS release_status,
    NULLIF(sm.lead_actors_count - (SELECT COUNT(DISTINCT ci.person_id) FROM cast_info ci WHERE ci.movie_id = sm.movie_id), 0) AS actor_difference
FROM Summary sm
LEFT JOIN KeywordMovies km ON sm.movie_id = km.movie_id
ORDER BY sm.production_year DESC, sm.lead_actors_count DESC;
