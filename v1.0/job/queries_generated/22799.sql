WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors,
        MAX(p.name) AS lead_actor
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
AllMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        fc.num_actors,
        fc.lead_actor,
        mwk.keywords,
        CASE 
            WHEN rt.title_rank = 1 THEN 'First Title'
            ELSE 'Other Title'
        END AS title_status
    FROM 
        RankedTitles rt
    LEFT JOIN 
        FilteredCast fc ON rt.title_id = fc.movie_id
    LEFT JOIN 
        MoviesWithKeywords mwk ON rt.title_id = mwk.movie_id
)
SELECT 
    am.title,
    am.production_year,
    am.num_actors,
    am.lead_actor,
    COALESCE(am.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN am.num_actors IS NULL THEN 'No cast listed'
        WHEN am.num_actors > 10 THEN 'Ensemble cast'
        WHEN am.lead_actor IS NULL THEN 'Unknown lead'
        ELSE 'Known lead'
    END AS actor_info,
    COUNT(*) OVER () AS total_movies,
    NTILE(10) OVER (ORDER BY am.production_year) AS decade_rank
FROM 
    AllMovies am
WHERE 
    am.production_year >= 2000
ORDER BY 
    am.production_year DESC, am.title;
