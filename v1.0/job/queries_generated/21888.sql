WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(rt.role) AS max_role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
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
MoviesWithCompanyInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        COUNT(DISTINCT mc.company_type_id) AS company_type_count
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON mc.movie_id = at.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        title m ON m.id = at.movie_id
    GROUP BY 
        m.id, m.title, cn.name
),
FinalResults AS (
    SELECT 
        mt.title,
        mt.production_year,
        mk.keywords,
        arc.movie_count,
        arc.max_role,
        mci.company_name,
        mci.company_type_count
    FROM 
        MoviesWithCompanyInfo mci
    JOIN 
        RankedTitles rt ON rt.title_id = mci.movie_id
    LEFT JOIN 
        ActorRoleCounts arc ON arc.person_id = ANY(ARRAY(SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = mci.movie_id))
    WHERE 
        rt.year_rank <= 5 
        AND mci.company_type_count > 0
)
SELECT 
    title,
    production_year,
    keywords,
    COALESCE(movie_count, 0) AS movie_count,
    max_role,
    company_name
FROM 
    FinalResults
WHERE 
    MAX(COALESCE(movie_count, 0)) OVER () > 1 
ORDER BY 
    production_year DESC, title;
