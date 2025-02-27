WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
CastDetails AS (
    SELECT 
        c.movie_id,
        p.name AS person_name,
        r.role AS role_name,
        COALESCE(aka.name, 'Unknown') AS aka_name
    FROM 
        cast_info c
    JOIN 
        name p ON c.person_id = p.imdb_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        aka_name aka ON p.imdb_id = aka.person_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CompleteInfo AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        cd.person_name,
        cd.role_name,
        cd.aka_name,
        co.company_name,
        co.company_type,
        rt.keyword
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CastDetails cd ON rt.title_id = cd.movie_id
    LEFT JOIN 
        CompanyDetails co ON rt.title_id = co.movie_id
)
SELECT 
    title,
    production_year,
    STRING_AGG(DISTINCT person_name || ' (' || COALESCE(aka_name, 'N/A') || ', ' || role_name || ')', '; ') AS cast,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS production_companies,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords
FROM 
    CompleteInfo
GROUP BY 
    title, production_year
ORDER BY 
    production_year DESC, title ASC;
