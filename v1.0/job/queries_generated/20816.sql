WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        c.name AS company_name,
        CASE 
            WHEN c.country_code IS NULL THEN 'Unknown'
            ELSE c.country_code
        END AS country
    FROM 
        RankedTitles rt
    LEFT JOIN 
        movie_companies mc ON rt.title_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        rt.rank <= 3  -- getting top 3 titles by kind_id
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
),
MoviePersonInfo AS (
    SELECT 
        t.title,
        t.production_year,
        p.name,
        pr.role_name,
        pr.role_count,
        t.country
    FROM 
        TopTitles t
    LEFT JOIN 
        complete_cast cc ON t.title_id = cc.movie_id
    LEFT JOIN 
        PersonRoles pr ON cc.subject_id = pr.person_id
    LEFT JOIN 
        aka_name p ON pr.person_id = p.person_id
),
KeywordInfo AS (
    SELECT 
        mt.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    mpi.title,
    mpi.production_year,
    mpi.name AS actor_name,
    mpi.role_name,
    mpi.role_count,
    COALESCE(ki.keywords, 'No Keywords') AS keywords
FROM 
    MoviePersonInfo mpi
LEFT JOIN 
    KeywordInfo ki ON mpi.title = ki.movie_id
WHERE 
    (mpi.role_name IS NOT NULL OR mpi.role_count > 1)
ORDER BY 
    mpi.production_year DESC, 
    mpi.title;
