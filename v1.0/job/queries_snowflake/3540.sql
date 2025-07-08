
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
DistinctGenres AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT kt.kind, ', ') WITHIN GROUP (ORDER BY kt.kind) AS genres
    FROM 
        movie_info mi 
    JOIN 
        info_type it ON mi.info_type_id = it.id 
    JOIN 
        movie_companies mc ON mi.movie_id = mc.movie_id 
    JOIN 
        kind_type kt ON mc.company_type_id = kt.id 
    WHERE 
        it.info = 'genre'
    GROUP BY 
        mi.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    COALESCE(c.company_count, 0) AS total_companies,
    COALESCE(pr.role, 'No role') AS primary_role,
    COALESCE(pr.role_count, 0) AS number_of_actors
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieKeywords k ON rt.title_id = k.movie_id
LEFT JOIN 
    CompanyCount c ON rt.title_id = c.movie_id
LEFT JOIN 
    PersonRoles pr ON rt.title_id = pr.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, rt.title ASC
LIMIT 100;
