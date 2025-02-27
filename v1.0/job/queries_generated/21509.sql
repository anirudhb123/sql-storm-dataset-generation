WITH RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_id
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_id
    FROM 
        title t
    JOIN 
        RecursiveTitleCTE r ON t.episode_of_id = r.title_id
), 
MovieInfoWithKeywords AS (
    SELECT 
        mt.movie_id,
        array_agg(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
PersonCastInfo AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.person_role_id IS NOT NULL
), 
MoviesWithCompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS company_note_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rt.title,
    rt.production_year,
    ARRAY_AGG(DISTINCT pi.actor_name) AS cast_actors,
    mwi.keywords,
    mwci.company_name,
    mwci.company_type,
    mwci.company_note_count,
    SUM(mwi.info_count) AS total_info_types
FROM 
    RecursiveTitleCTE rt
LEFT JOIN 
    PersonCastInfo pi ON rt.id = pi.movie_id
LEFT JOIN 
    MovieInfoWithKeywords mwi ON rt.imdb_id = mwi.movie_id
LEFT JOIN 
    MoviesWithCompanyInfo mwci ON rt.id = mwci.movie_id
WHERE 
    rt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
GROUP BY 
    rt.title, rt.production_year, mwi.keywords, mwci.company_name, mwci.company_type, mwci.company_note_count
ORDER BY 
    rt.production_year DESC, rt.title;
