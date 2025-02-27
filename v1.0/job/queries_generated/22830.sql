WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        c.name AS actor_name,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        name c ON ci.person_id = c.id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, c.name, r.role
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
NullCheck AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.id IS NULL OR ci.note IS NULL
    GROUP BY 
        ci.movie_id
),
FinalResult AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        cd.actor_name,
        cd.role_name,
        mk.keywords,
        COALESCE(nc.total_cast, 0) AS null_cast_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CastDetails cd ON rt.title_id = cd.movie_id
    LEFT JOIN 
        MoviesWithKeywords mk ON rt.title_id = mk.movie_id
    LEFT JOIN 
        NullCheck nc ON rt.title_id = nc.movie_id
)
SELECT 
    fr.title_id,
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.role_name,
    fr.keywords,
    fr.null_cast_count,
    CASE 
        WHEN fr.null_cast_count > 0 THEN 'Check null cast info'
        ELSE 'No null cast info'
    END AS null_cast_info,
    CASE
        WHEN fr.production_year IS NULL THEN 'produced in an unknown year'
        WHEN fr.production_year < 2000 THEN 'Classic'
        WHEN fr.production_year BETWEEN 2000 AND 2010 THEN '21st Century'
        ELSE 'Recent'
    END AS production_milestone
FROM 
    FinalResult fr
WHERE 
    fr.year_rank <= 10
ORDER BY 
    fr.production_year DESC, fr.title;
