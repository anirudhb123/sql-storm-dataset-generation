
WITH RECURSIVE RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyGenres AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT kt.kind, ', ') WITHIN GROUP (ORDER BY kt.kind) AS genres
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        kind_type kt ON ct.id = kt.id
    GROUP BY 
        mc.movie_id
), 
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ac.actor_count,
        cg.genres,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        ActorCounts ac ON t.id = ac.movie_id
    LEFT JOIN 
        CompanyGenres cg ON t.id = cg.movie_id
    WHERE 
        t.production_year IS NOT NULL
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.genres,
    CASE 
        WHEN md.actor_count IS NULL THEN 'No Actors' 
        ELSE CAST(md.actor_count AS VARCHAR) || ' Actor(s)' 
    END AS actor_count_description,
    CASE 
        WHEN md.year_rank <= 5 THEN 'Top 5 Movies of Year ' || md.production_year
        ELSE 'Other Movies'
    END AS ranking_description
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
