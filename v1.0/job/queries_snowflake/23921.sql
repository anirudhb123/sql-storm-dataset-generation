
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS row_num
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS film_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        title m ON mc.movie_id = m.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title_id,
    rt.title AS movie_title,
    rt.production_year,
    at.actor_name,
    cd.company_name,
    cd.company_type,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    rt.row_num,
    at.movie_rank,
    COUNT(DISTINCT c.note) AS unique_role_notes
FROM 
    RankedMovies rt
LEFT JOIN 
    ActorTitles at ON rt.title = at.movie_title AND rt.production_year = at.production_year
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    cast_info c ON at.actor_id = c.person_id AND rt.title_id = c.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE 
    (at.movie_rank IS NULL OR at.movie_rank < 3) AND
    (rt.production_year BETWEEN 1990 AND 2023 OR rt.production_year IS NULL)
GROUP BY 
    rt.title_id, rt.title, rt.production_year, at.actor_name, cd.company_name, cd.company_type, mk.keywords, rt.row_num, at.movie_rank
ORDER BY 
    rt.production_year DESC, rt.title ASC
LIMIT 100;
