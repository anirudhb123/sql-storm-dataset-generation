WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        tt.title AS movie_title,
        tt.production_year,
        ct.kind AS role_kind
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN title tt ON ci.movie_id = tt.id
    JOIN role_type ct ON ci.role_id = ct.id
    WHERE ak.name IS NOT NULL
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_movies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, cn.name, ct.kind
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    ai.actor_name,
    ai.movie_title,
    ai.production_year,
    ci.company_name,
    ci.company_type,
    kc.keyword_count,
    rt.rank
FROM actor_info ai
LEFT JOIN company_info ci ON ai.movie_title = ci.movie_name
LEFT JOIN keyword_counts kc ON ai.movie_title = kc.movie_id
JOIN ranked_titles rt ON ai.movie_title = rt.title AND ai.production_year = rt.production_year
WHERE rt.rank <= 5
ORDER BY ai.actor_name, ai.production_year DESC;
