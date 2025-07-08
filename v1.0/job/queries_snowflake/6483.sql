WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mi.info_type_id) DESC) AS rank
    FROM title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id, t.title, t.production_year
),
popular_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.info_count,
        rm.keyword_count
    FROM ranked_movies rm
    WHERE rm.rank <= 10
)
SELECT 
    pm.title,
    pm.production_year,
    ak.name AS actor_name,
    ct.kind AS company_type,
    ck.keyword AS movie_keyword
FROM popular_movies pm
JOIN complete_cast cc ON pm.movie_id = cc.movie_id
JOIN cast_info ci ON cc.subject_id = ci.id
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN movie_companies mc ON pm.movie_id = mc.movie_id
JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_keyword mk ON pm.movie_id = mk.movie_id
LEFT JOIN keyword ck ON mk.keyword_id = ck.id
ORDER BY pm.production_year DESC, pm.title ASC;
