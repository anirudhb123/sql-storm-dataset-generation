
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title AS at
    LEFT JOIN 
        cast_info AS ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
PopularTitles AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies AS mc
    INNER JOIN 
        company_name AS cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    INNER JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    pt.title,
    pt.production_year,
    COALESCE(cd.company_names, 'No Companies') AS companies,
    COALESCE(cd.company_types, 'No Types') AS types,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    PopularTitles AS pt
LEFT JOIN 
    CompanyDetails AS cd ON pt.production_year = cd.movie_id
LEFT JOIN 
    MovieKeywords AS mk ON pt.production_year = mk.movie_id
ORDER BY 
    pt.production_year DESC, 
    pt.title ASC;
