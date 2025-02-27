WITH RankedTitles AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank_year,
        COUNT(c.id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id, 
        mc.company_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        mc.note IS NOT NULL
),
NameInfo AS (
    SELECT 
        DISTINCT 
        n.name, 
        n.gender,
        COUNT(pi.id) OVER (PARTITION BY n.id) AS info_count
    FROM 
        name n
    LEFT JOIN 
        person_info pi ON n.imdb_id = pi.person_id
    WHERE 
        n.gender IS NOT NULL
),
MovieKeywordInfo AS (
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
ComplexQuery AS (
    SELECT 
        rt.title, 
        rt.production_year, 
        rt.cast_count, 
        ci.company_name,
        ci.company_type,
        nk.name AS character_name,
        nk.gender,
        mk.keywords,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rt.id) AS complete_cast_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyInfo ci ON rt.id = ci.movie_id
    LEFT JOIN 
        char_name nk ON nk.imdb_index = rt.title
    LEFT JOIN 
        MovieKeywordInfo mk ON mk.movie_id = rt.id
    WHERE 
        (rt.rank_year <= 5 OR ci.company_type = 'Distributor')
        AND (nk.gender = 'F' OR nk.gender IS NULL)
)
SELECT 
    *
FROM 
    ComplexQuery
WHERE 
    complete_cast_count >= 1
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 50
OFFSET 0;
