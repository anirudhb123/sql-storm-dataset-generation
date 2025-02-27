WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
nickname_aggregation AS (
    SELECT 
        a.person_id,
        STRING_AGG(a.name, ', ') AS all_nicknames
    FROM aka_name a
    GROUP BY a.person_id
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.nr_order,
        r.role,
        n.all_nicknames
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    LEFT JOIN nickname_aggregation n ON ci.person_id = n.person_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT CONCAT(cn.name, ' (', ct.kind, ')'), ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
filtered_movies AS (
    SELECT 
        ct.movie_id,
        ct.person_id,
        ct.role,
        ci.companies,
        rt.title,
        rt.production_year
    FROM cast_with_roles ct
    JOIN company_info ci ON ct.movie_id = ci.movie_id
    JOIN ranked_titles rt ON ct.movie_id = rt.title_id
    WHERE 
        ct.nr_order = 1 
        AND rt.year_rank <= 3  -- Get top 3 recent films per year
)
SELECT 
    f.title,
    f.production_year,
    f.role,
    f.companies,
    COALESCE(n.all_nicknames, 'No nicknames') AS nicknames,
    (SELECT COUNT(*) FROM movie_keyword WHERE movie_id = f.movie_id) AS keyword_count,
    (SELECT COUNT(DISTINCT ci2.person_id) 
     FROM cast_info ci2 
     WHERE ci2.movie_id = f.movie_id AND ci2.person_role_id IS NOT NULL
    ) AS distinct_actors_count,
    CASE 
        WHEN f.production_year IS NULL THEN 'Unknown Year'
        ELSE f.production_year::text
    END AS production_year_display
FROM filtered_movies f
ORDER BY f.production_year DESC, f.title;
