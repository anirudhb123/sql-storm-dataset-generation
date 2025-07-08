
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
ActorRoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopFilms AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.title_rank,
        mcc.company_count,
        arc.distinct_roles,
        COALESCE(SUM(CASE WHEN mk.id IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count,
        CASE 
            WHEN mcc.company_count IS NULL OR arc.distinct_roles IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS company_role_info
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieCompanyCounts mcc ON rt.title_id = mcc.movie_id
    LEFT JOIN 
        ActorRoleCounts arc ON rt.title_id = arc.movie_id
    LEFT JOIN 
        movie_keyword mk ON rt.title_id = mk.movie_id
    WHERE 
        rt.title IS NOT NULL
    GROUP BY 
        rt.title, rt.production_year, rt.title_rank, mcc.company_count, arc.distinct_roles
)
SELECT 
    tf.title,
    tf.production_year,
    tf.title_rank,
    tf.company_count,
    tf.distinct_roles,
    tf.keyword_count,
    tf.company_role_info
FROM 
    TopFilms tf
WHERE 
    tf.company_count > 1 AND 
    (tf.distinct_roles > 3 OR tf.keyword_count > 5)
ORDER BY 
    tf.production_year DESC, 
    tf.title_rank;
