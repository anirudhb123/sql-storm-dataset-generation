WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM title t
    JOIN cast_info c ON c.movie_id = t.id
    JOIN aka_name ak ON ak.person_id = c.person_id
    WHERE t.production_year > 2000
    GROUP BY t.id, t.title, t.production_year
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
),
company_info AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON cn.id = mc.company_id
    JOIN company_type ct ON ct.id = mc.company_type_id
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.aka_names,
    mk.keywords,
    ci.companies,
    ci.company_types
FROM ranked_movies rm
LEFT JOIN movie_keywords mk ON mk.movie_id = rm.movie_id
LEFT JOIN company_info ci ON ci.movie_id = rm.movie_id
ORDER BY rm.production_year DESC, rm.total_cast DESC;
