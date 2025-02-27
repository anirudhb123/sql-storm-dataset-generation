WITH RankedMovies AS (
    SELECT 
        tk.id AS title_id, 
        tk.title, 
        tk.production_year,
        ROW_NUMBER() OVER (PARTITION BY tk.production_year ORDER BY tk.production_year DESC) AS rank
    FROM 
        aka_title tk 
    WHERE 
        tk.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActiveCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        r.title_id, 
        r.title, 
        r.production_year, 
        ac.actor_count, 
        ac.actor_names
    FROM 
        RankedMovies r
    LEFT JOIN 
        ActiveCast ac ON r.title_id = ac.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS actor_count,
    md.actor_names,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = md.title_id 
          AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Oscars Won') 
          AND mi.info IS NOT NULL
    ) AS has_oscars
FROM 
    MovieDetails md
WHERE 
    (md.actor_count IS NOT NULL AND md.actor_count > 5) 
    OR (md.actor_names IS NOT NULL AND md.actor_names LIKE '%John%')
ORDER BY 
    md.production_year DESC, 
    md.title;
