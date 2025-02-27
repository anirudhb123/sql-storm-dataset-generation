WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.id) AS rank
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
CastingInfo AS (
    SELECT 
        c.movie_id,
        c.person_id,
        ci.kind AS role_type,
        COUNT(c.nr_order) AS role_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info AS c
    JOIN 
        comp_cast_type AS ci ON c.person_role_id = ci.id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        c.movie_id, c.person_id, ci.kind
),
FilteredMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        MAX(ci.role_count) AS max_role_count,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM 
        RankedTitles AS rt
    LEFT JOIN 
        CastingInfo AS ci ON rt.title_id = ci.movie_id
    WHERE 
        rt.rank <= 3 
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
    HAVING 
        MAX(ci.role_count) > 1 AND COUNT(DISTINCT ci.person_id) > 5 
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        COUNT(m.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS m
    WHERE 
        m.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
    GROUP BY 
        m.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.max_role_count,
    fm.total_actors,
    COALESCE(mk.keyword_count, 0) AS action_keyword_count,
    CASE 
        WHEN fm.total_actors > 10 THEN 'Ensemble Cast' 
        ELSE 'Standard Cast' 
    END AS cast_type,
    ROUND((EXTRACT(YEAR FROM cast('2024-10-01' as date)) - fm.production_year) * 1.0 / NULLIF(EXTRACT(YEAR FROM cast('2024-10-01' as date)) - 2000, 0), 2) AS age_factor 
FROM 
    FilteredMovies AS fm
LEFT JOIN 
    MovieKeywords AS mk ON fm.title_id = mk.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;