WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS title_id,
        ak.name AS person_name,
        ci.nr_order AS cast_order,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ci.nr_order) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
KeywordUsage AS (
    SELECT 
        m.title AS movie_title,
        k.keyword 
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
CompanyInfo AS (
    SELECT 
        m.title AS movie_title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title m ON mc.movie_id = m.id
    WHERE 
        m.production_year >= 2000
)
SELECT 
    rt.movie_title,
    rt.production_year,
    rt.person_name,
    rt.rank AS cast_rank,
    GROUP_CONCAT(ku.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT ci.company_name || ' (' || ci.company_type || ')') AS companies
FROM 
    RankedTitles rt
LEFT JOIN 
    KeywordUsage ku ON rt.movie_title = ku.movie_title
LEFT JOIN 
    CompanyInfo ci ON rt.movie_title = ci.movie_title
GROUP BY 
    rt.movie_title, rt.production_year, rt.person_name, rt.rank
ORDER BY 
    rt.production_year DESC, rt.movie_title;
