
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        LISTAGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.note IS NULL OR ci.note != 'stand-in'
    GROUP BY 
        ci.movie_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(k.keyword) OVER (PARTITION BY mk.movie_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    rt.title, 
    rt.production_year,
    ARRAY_AGG(DISTINCT cm.company_name) AS companies,
    cd.total_actors,
    cd.actor_names,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COUNT(*) FILTER (WHERE rt.production_year = 2023) OVER () AS total_movies_2023,
    CASE 
        WHEN rt.production_year IS NOT NULL THEN 'Produced'
        ELSE 'Unknown' END AS production_status,
    CASE 
        WHEN COUNT(mk.keyword) > 0 THEN 'Has Keywords'
        ELSE 'No Keywords' END AS keyword_status
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id AND cm.company_rank = 1
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.title_rank < 3
GROUP BY 
    rt.title, rt.production_year, cd.total_actors, cd.actor_names, mk.keyword_count
ORDER BY 
    rt.production_year DESC, rt.title;
