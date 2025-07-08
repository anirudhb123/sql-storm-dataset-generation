
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rnk
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
TitleWithNames AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ak.name AS aka_name,
        cn.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY rt.title_id ORDER BY ak.name) AS name_rnk
    FROM 
        RankedTitles rt
    LEFT JOIN 
        complete_cast cc ON rt.title_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON rt.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
)
SELECT 
    title_id,
    title,
    production_year,
    LISTAGG(DISTINCT aka_name, ', ') WITHIN GROUP (ORDER BY aka_name) AS all_aka_names,
    LISTAGG(DISTINCT company_name, ', ') WITHIN GROUP (ORDER BY company_name) AS all_company_names
FROM 
    TitleWithNames
WHERE 
    name_rnk = 1
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, title;
