
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS ranking
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        t.production_year IS NOT NULL
),

ActorPerformance AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id
),

CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    ap.movie_count AS actor_movie_count,
    ap.has_note_ratio,
    cm.company_count,
    COALESCE(rm.keyword, 'No Keyword') AS movie_keyword,
    CASE 
        WHEN ap.has_note_ratio >= 0.5 THEN 'High Note Presence'
        ELSE 'Low Note Presence'
    END AS NotePresence
FROM 
    RankedMovies rm
FULL OUTER JOIN 
    ActorPerformance ap ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.person_id = ap.person_id AND ci.movie_id = rm.title_id
    )
LEFT JOIN 
    CompanyMovies cm ON rm.title_id = cm.movie_id
WHERE 
    rm.ranking = 1
ORDER BY 
    rm.production_year DESC, 
    ap.movie_count DESC, 
    cm.company_count ASC
LIMIT 100;
