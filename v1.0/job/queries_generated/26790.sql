WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
),
filtered_cast AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        COUNT(*) AS role_count
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    WHERE ca.nr_order IS NOT NULL
    GROUP BY ca.movie_id, a.name
),
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE mc.note IS NULL
),
enhanced_movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        fc.actor_name,
        COUNT(fc.role_count) AS total_roles,
        ARRAY_AGG(DISTINCT co.company_name) AS production_companies,
        ARRAY_AGG(DISTINCT co.company_type) AS company_types,
        STRING_AGG(DISTINCT rt.keyword, ', ') AS associated_keywords
    FROM title t
    LEFT JOIN filtered_cast fc ON t.id = fc.movie_id
    LEFT JOIN company_info co ON t.id = co.movie_id
    LEFT JOIN ranked_titles rt ON t.id = rt.title
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, fc.actor_name
)
SELECT
    em.title AS movie_title,
    em.production_year,
    em.actor_name,
    em.total_roles,
    em.production_companies,
    em.company_types,
    em.associated_keywords
FROM enhanced_movie_data em
ORDER BY em.production_year DESC, em.total_roles DESC, em.movie_title;
