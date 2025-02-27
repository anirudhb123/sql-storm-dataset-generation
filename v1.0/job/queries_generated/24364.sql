WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS role_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        STRING_AGG(DISTINCT CASE WHEN c.note IS NOT NULL THEN c.note ELSE 'No notes' END, ', ') AS notes
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.person_id, a.name, c.movie_id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, '; ') AS company_names
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    ai.name AS actor_name,
    ai.role_count,
    ai.roles,
    ci.company_count,
    ci.company_names,
    ki.keywords,
    COALESCE(NULLIF(ai.notes, ''), 'No actors notes available') AS actor_notes
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.title_id = ai.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.title_id = ci.movie_id
LEFT JOIN 
    KeywordInfo ki ON rm.title_id = ki.movie_id
WHERE 
    (rm.production_year > 2000 AND ai.role_count > 1) 
    OR (rm.production_year <= 2000 AND ai.role_count = 1)
ORDER BY 
    rm.production_year DESC, 
    ai.role_count DESC NULLS LAST, 
    rm.title;
