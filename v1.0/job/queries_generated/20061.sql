WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        COALESCE(k.keyword, 'N/A') AS keyword,
        a.name AS actor_name,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS featured_actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        cast_info c ON c.movie_id = m.movie_id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, a.name
),
HighRatedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.actor_name,
        md.actor_count,
        md.featured_actor_count
    FROM 
        MovieDetails md
    WHERE 
        md.actor_count > 5 AND 
        (md.production_year >= 2000 OR md.keyword LIKE '%Drama%')
),
FilteredMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS actor_rank
    FROM 
        HighRatedMovies
)
SELECT 
    f.title,
    f.production_year,
    f.keyword,
    f.actor_name,
    f.actor_count,
    f.featured_actor_count,
    CASE 
        WHEN f.actor_rank = 1 THEN 'Best'
        WHEN f.actor_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS ranking_category
FROM 
    FilteredMovies f
WHERE 
    f.actor_count > 1
    AND f.actor_name IS NOT NULL
ORDER BY 
    f.production_year DESC,
    f.actor_count DESC,
    f.title;

