WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) as rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        STRING_AGG(DISTINCT t.title, ', ') FILTER (WHERE t.production_year > 2000) AS recent_titles,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.person_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        MIN(CASE WHEN mc.note IS NOT NULL THEN mc.note ELSE 'N/A' END) AS company_notes
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id, cn.name
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(a.total_movies, 0) AS actor_count,
        COALESCE(c.total_companies, 0) AS company_count,
        COALESCE(c.company_notes, 'No notes') AS company_notes
    FROM 
        RankedMovies m
    LEFT JOIN 
        ActorStats a ON m.movie_id = a.person_id
    LEFT JOIN 
        CompanyStats c ON m.movie_id = c.movie_id
)
SELECT 
    md.title,
    md.production_year,
    CASE 
        WHEN md.actor_count > 0 AND md.company_count > 0 THEN 'Active'
        WHEN md.actor_count = 0 AND md.company_count = 0 THEN 'Inactive'
        ELSE 'Mixed'
    END AS status,
    md.company_notes,
    RANK() OVER (ORDER BY md.actor_count DESC, md.company_count DESC) as movie_rank
FROM 
    MovieDetails md
WHERE 
    md.actor_count > 0 OR md.company_count > 0
ORDER BY 
    md.production_year DESC, movie_rank;
