
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank_per_kind
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieWithActors AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        MAX(a.name) AS lead_actor_name
    FROM 
        cast_info ca
    INNER JOIN 
        aka_name a ON ca.person_id = a.person_id
    GROUP BY 
        ca.movie_id
),
MoviesWithKeywords AS (
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
FinalMovieData AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        m.actor_count,
        m.lead_actor_name,
        mk.keywords
    FROM 
        RankedTitles r
    LEFT JOIN 
        MovieWithActors m ON r.title_id = m.movie_id
    LEFT JOIN 
        MoviesWithKeywords mk ON r.title_id = mk.movie_id
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.lead_actor_name, 'Unknown Lead Actor') AS lead_actor,
    COALESCE(f.keywords, 'No Keywords') AS keywords_info,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(f.title) OVER (PARTITION BY f.production_year) AS num_titles_in_year
FROM 
    FinalMovieData f
WHERE 
    f.actor_count IS NOT NULL
    AND f.production_year > 1990
GROUP BY 
    f.title, 
    f.production_year, 
    f.lead_actor_name, 
    f.keywords
ORDER BY 
    f.production_year DESC, f.title;
