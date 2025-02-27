WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
EnhancedCast AS (
    SELECT 
        a.person_id,
        a.name,
        ci.movie_id,
        r.role,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        ActorRoles r ON ci.movie_id = r.movie_id
    LEFT JOIN 
        MovieKeywords mk ON ci.movie_id = mk.movie_id
),
FinalBenchmark AS (
    SELECT 
        t.title,
        t.production_year,
        ec.name AS actor_name,
        ec.role,
        ec.keywords,
        ec.actor_rank,
        rt.title_rank
    FROM 
        RankedTitles rt
    JOIN 
        complete_cast cc ON rt.title_id = cc.movie_id
    JOIN 
        EnhancedCast ec ON cc.subject_id = ec.person_id
    ORDER BY 
        rt.production_year DESC, 
        rt.title_rank ASC, 
        ec.actor_rank ASC
)
SELECT 
    fb.*
FROM 
    FinalBenchmark fb
WHERE 
    (fb.role IS NOT NULL OR fb.keywords IS NOT NULL)
    AND (fb.production_year <> 2023 OR fb.title LIKE '%Mystery%')
    AND NOT EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = fb.title_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
        AND mi.info IS NULL
    )
FETCH FIRST 100 ROWS ONLY;

