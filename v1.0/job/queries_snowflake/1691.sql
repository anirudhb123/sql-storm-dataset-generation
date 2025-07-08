
WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword IN ('Action', 'Drama') 
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    fm.title AS movie_title,
    fm.production_year,
    fm.keyword AS movie_keyword,
    ci.company_names,
    ci.total_companies,
    rt.title_rank
FROM 
    FilteredMovies fm
LEFT JOIN 
    CompanyInfo ci ON fm.id = ci.movie_id
LEFT JOIN 
    RankedTitles rt ON fm.title = rt.title AND fm.production_year = rt.production_year
WHERE 
    ci.total_companies IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    rt.title_rank ASC;
