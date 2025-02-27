WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_info mi ON t.id = mi.movie_id
    WHERE mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Plot'
    ) AND mi.info IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
movie_company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS production_companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.movie_keyword,
    cs.actor_count,
    cs.actor_names,
    mcs.company_count,
    mcs.production_companies
FROM ranked_movies rm
JOIN cast_summary cs ON rm.movie_id = cs.movie_id
JOIN movie_company_summary mcs ON rm.movie_id = mcs.movie_id
WHERE rm.year_rank <= 5
ORDER BY rm.production_year DESC, rm.movie_title;
