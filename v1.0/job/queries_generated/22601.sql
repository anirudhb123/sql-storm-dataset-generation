WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) as ranking
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
        count(DISTINCT ci.movie_id) AS movie_count,
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
    ActorPerformance ap ON rm.title_id = (
        SELECT 
            ci.movie_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.person_id = ap.person_id 
        LIMIT 1
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

This SQL query uses Common Table Expressions (CTEs) to generate various subqueries addressing the following aspects: 
- `RankedMovies` extracts movie titles alongside their production year and associated keywords, while also providing a ranking mechanism.
- `ActorPerformance` computes statistical measures related to actors and their performance, using `COUNT` and `AVG` functions to interpret the data.
- `CompanyMovies` summarizes the number of distinct companies involved in each movie.

The final `SELECT` statement combines results from these CTEs using a `FULL OUTER JOIN`, allowing retrieval of movies even if there are no associated actors or companies. It incorporates calculated fields and logical case expressions to enrich the results, using `COALESCE` for handling potential NULL keyword values and returning descriptive categories based on calculated ratios. 

The entire query is concluded with order criteria and limits to present 100 results based on the defined logic.
