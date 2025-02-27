WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        t.kind AS title_kind,
        COALESCE(landing.company_count, 0) AS company_count,
        COALESCE(role_info.num_roles, 0) AS num_roles,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_order
    FROM
        aka_title mt
    LEFT JOIN (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM
            movie_companies mc
        GROUP BY
            mc.movie_id
    ) landing ON mt.id = landing.movie_id
    LEFT JOIN (
        SELECT
            ci.movie_id,
            COUNT(DISTINCT ci.role_id) AS num_roles
        FROM
            cast_info ci
        GROUP BY
            ci.movie_id
    ) role_info ON mt.id = role_info.movie_id
    JOIN kind_type t ON mt.kind_id = t.id
    WHERE
        mt.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT
        mh.*,
        CASE
            WHEN mh.company_count = 0 THEN 'No affiliated companies'
            WHEN mh.num_roles > 10 THEN 'Star-studded cast'
            ELSE 'Under the radar'
        END AS movie_status
    FROM
        MovieHierarchy mh
    WHERE
        mh.production_year >= (SELECT MAX(production_year) FROM aka_title) - 10  -- filter for last decade
        AND mh.title_kind NOT IN (
            SELECT kt.kind FROM kind_type kt WHERE kt.kind LIKE '%TV%'
        )
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY num_roles DESC) AS rank_by_roles
    FROM 
        FilteredMovies
    WHERE 
        movie_status = 'Star-studded cast'
)
SELECT
    fm.title,
    fm.production_year,
    fm.movie_status,
    CASE 
        WHEN fm.company_count IS NULL THEN 'No companies linked'
        ELSE 'Companies linked: ' || fm.company_count::text
    END AS companies_report,
    string_agg(DISTINCT r.role::text, ', ') AS roles_list
FROM 
    RankedMovies fm
LEFT JOIN
    cast_info c ON fm.movie_id = c.movie_id
LEFT JOIN
    role_type r ON c.role_id = r.id
WHERE 
    fm.rank_by_roles <= 5   -- Top 5 by roles
GROUP BY 
    fm.title, fm.production_year, fm.movie_status, fm.company_count
ORDER BY
    fm.production_year DESC, fm.rank_by_roles;
