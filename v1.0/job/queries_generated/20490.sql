WITH RecursiveRoleHierarchy AS (
    SELECT 
        ct.id AS role_id,
        ct.kind AS role_name,
        0 AS level
    FROM 
        comp_cast_type ct
    WHERE 
        ct.kind IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ct.id AS role_id,
        ct.kind AS role_name,
        r.level + 1
    FROM 
        comp_cast_type ct
    JOIN 
        RecursiveRoleHierarchy r ON ct.id = r.role_id
    WHERE 
        r.level < 3 -- limit depth to 3
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT kn.keyword ORDER BY kn.keyword), 'No Keywords') AS keywords,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name), 'No Company') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kn ON kn.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (ORDER BY movie_id) AS rank,
        DENSE_RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS production_year_rank
    FROM 
        MovieDetails md
    WHERE 
        production_year IS NOT NULL
),
FinalSelection AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        rm.production_year_rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10 OR 
        (rm.production_year_rank <= 5 AND rm.rank > 10)
)
SELECT 
    fs.*,
    CASE 
        WHEN fs.production_year < 2000 THEN 'Classic'
        WHEN fs.production_year >= 2000 AND fs.production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COALESCE(NULLIF(fs.keywords, 'No Keywords'), 'Keywords Unavailable') AS keywords_status,
    CASE 
        WHEN fs.companies LIKE '%Paramount%' THEN 'Big Company'
        ELSE 'Independent'
    END AS company_status
FROM 
    FinalSelection fs
LEFT JOIN 
    aka_name an ON an.person_id IN (SELECT person_id FROM cast_info ci WHERE ci.movie_id = fs.movie_id)
WHERE 
    an.surname_pcode IS NOT NULL
    AND an.id NOT IN (
        SELECT id FROM name WHERE gender = 'F'
    )
ORDER BY 
    fs.production_year DESC, fs.cast_count DESC;
