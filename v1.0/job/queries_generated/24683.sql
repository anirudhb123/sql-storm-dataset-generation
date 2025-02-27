WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS role_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name, c.movie_id
    HAVING 
        COUNT(DISTINCT c.role_id) > 1
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM  
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CompleteMovieDetails AS (
    SELECT 
        mo.id AS movie_id,
        mo.title,
        coalesce(ai.name, 'Unnamed Actor') AS actor_name,
        ko.keywords,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS total_info
    FROM 
        aka_title mo
    LEFT JOIN 
        cast_info ci ON mo.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    LEFT JOIN
        MoviesWithKeywords ko ON mo.id = ko.movie_id
    LEFT JOIN 
        movie_info mi ON mo.id = mi.movie_id
    GROUP BY 
        mo.id, mo.title, ai.name, ko.keywords
),
FinalOutput AS (
    SELECT 
        CMD.movie_id,
        CMD.title,
        CMD.actor_name,
        CMD.keywords,
        CMD.total_info,
        CASE 
            WHEN CMD.total_info = 0 THEN 'No Info'
            WHEN CMD.actor_name IS NULL THEN 'No actor assigned'
            ELSE 'Info available'
        END AS info_status
    FROM 
        CompleteMovieDetails CMD
)
SELECT 
    F.movie_id,
    F.title,
    F.actor_name,
    F.keywords,
    F.info_status,
    CASE 
        WHEN F.keywords IS NULL THEN 'No Keywords'
        ELSE 'Keywords Present'
    END AS keyword_status
FROM 
    FinalOutput F
WHERE 
    F.total_info > 0 
    AND (F.actor_name IS NOT NULL OR F.actor_name <> 'Unnamed Actor')
ORDER BY 
    F.total_info DESC, F.title;
