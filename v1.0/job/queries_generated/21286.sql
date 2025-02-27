WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year ASC) as rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL AND t.production_year > 2000
), 
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(ci.nr_order) AS highest_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_kind
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
), 
TitleActors AS (
    SELECT 
        md.title_id,
        md.title,
        cd.actor_count,
        cd.highest_order,
        COALESCE(cd.highest_order, 0) AS max_order,
        COALESCE(md.keyword, 'No Keyword') AS movie_keyword
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.title_id = cd.movie_id
)
SELECT 
    ta.title,
    ta.production_year,
    ta.actor_count,
    ta.max_order,
    ta.movie_keyword,
    cb.company_name,
    cb.company_kind
FROM 
    TitleActors ta
LEFT JOIN 
    CompanyDetails cb ON ta.title_id = cb.movie_id
WHERE 
    ta.actor_count > 1 
    AND ta.max_order IS NOT NULL
ORDER BY 
    ta.production_year DESC, ta.title;
