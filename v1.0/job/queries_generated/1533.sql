WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role = 'actor')
),
FilteredMovies AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year
    FROM 
        ActorMovies am
    WHERE 
        am.rn <= 5
),
MovieKeywords AS (
    SELECT 
        fm.actor_name,
        fm.movie_title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        FilteredMovies fm
    JOIN 
        movie_keyword mk ON fm.movie_title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id)
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.actor_name, fm.movie_title
),
FinalResults AS (
    SELECT 
        f.actor_name,
        f.movie_title,
        f.keywords,
        COALESCE(STRING_AGG(DISTINCT c.name, ', '), 'No Companies') AS company_names
    FROM 
        MovieKeywords f
    LEFT JOIN 
        movie_companies mc ON f.movie_title = (SELECT title FROM aka_title WHERE movie_id = mc.movie_id)
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        f.actor_name, f.movie_title, f.keywords
)
SELECT 
    fr.actor_name,
    fr.movie_title,
    fr.keywords,
    CASE 
        WHEN fr.company_names IS NULL THEN 'Unknown'
        ELSE fr.company_names 
    END AS company_names
FROM 
    FinalResults fr
WHERE 
    fr.keywords IS NOT NULL
ORDER BY 
    fr.actor_name, fr.production_year DESC;
