
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        ac.movie_id,
        COALESCE(NULLIF(ac.role_id, 0), -1) AS role_id,
        COALESCE(LOWER(ac.note), 'unknown') AS role_note
    FROM 
        aka_name ak
    JOIN 
        cast_info ac ON ak.person_id = ac.person_id
    LEFT JOIN 
        cast_info ai ON ac.movie_id = ai.movie_id AND ai.person_role_id = ac.person_role_id
    WHERE 
        ak.name IS NOT NULL
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
MovieKeywords AS (
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
FilteredMovies AS (
    SELECT 
        r.title_id, 
        r.title, 
        r.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT ai.actor_name) AS actor_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActorInfo ai ON r.title_id = ai.movie_id
    LEFT JOIN 
        MovieKeywords mk ON r.title_id = mk.movie_id
    WHERE 
        r.year_rank < 5 
    GROUP BY 
        r.title_id, r.title, r.production_year, mk.keywords
    HAVING 
        COUNT(DISTINCT ai.actor_name) > 0 
    ORDER BY 
        r.production_year DESC, r.title
)
SELECT 
    fm.title, 
    fm.production_year,
    COALESCE(cd.company_name, 'Unknown Company') AS company,
    cd.company_type,
    fm.keywords,
    fm.actor_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    CompanyDetails cd ON fm.title_id = cd.movie_id
WHERE 
    (fm.production_year IS NOT NULL AND fm.production_year > 2000)
    OR 
    (fm.production_year IS NULL AND EXISTS (SELECT 1 FROM title t WHERE t.id = fm.title_id))
ORDER BY 
    fm.production_year DESC, fm.title;
