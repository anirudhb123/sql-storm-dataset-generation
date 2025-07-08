WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredAkaNames AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name,
        a.imdb_index
    FROM 
        aka_name a
    WHERE 
        a.name_pcode_cf IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, c.person_id, r.role
),
CompanyProduction AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ak.name AS aka_name,
    am.role,
    cp.company_name,
    cp.company_type,
    mkc.keyword_count
FROM 
    RankedTitles rt
JOIN 
    ActorMovies am ON rt.title_id = am.movie_id
JOIN 
    FilteredAkaNames ak ON am.person_id = ak.person_id
JOIN 
    CompanyProduction cp ON am.movie_id = cp.movie_id
LEFT JOIN 
    MovieKeywordCount mkc ON rt.title_id = mkc.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, ak.name ASC;
