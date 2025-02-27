WITH Recursive MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS total_movies,
        AVG(t.production_year) FILTER (WHERE t.production_year IS NOT NULL) AS avg_movie_year
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    GROUP BY 
        a.person_id, a.name
),
HighlyRatedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT l.linked_movie_id) AS total_links
    FROM 
        aka_title m
    LEFT JOIN 
        movie_link l ON m.id = l.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title
    HAVING 
        COUNT(DISTINCT l.linked_movie_id) > 5
),
FinalResults AS (
    SELECT 
        ad.person_id,
        ad.name,
        ad.total_movies,
        ad.avg_movie_year,
        mt.title,
        mt.production_year,
        COALESCE(hm.total_links, 0) AS total_links
    FROM 
        ActorDetails ad
    JOIN 
        MovieTitles mt ON ad.total_movies > 3
    LEFT JOIN 
        HighlyRatedMovies hm ON mt.title = hm.title
)
SELECT 
    fr.name,
    fr.production_year,
    SUM(fr.total_links) OVER (PARTITION BY fr.name ORDER BY fr.production_year DESC) AS cumulative_links,
    CASE 
        WHEN fr.avg_movie_year < 2005 THEN 'Classic Actor'
        WHEN fr.avg_movie_year BETWEEN 2005 AND 2015 THEN 'Modern Actor'
        ELSE 'New Age Actor'
    END AS actor_category
FROM 
    FinalResults fr
WHERE 
    fr.total_links IS NOT NULL OR fr.total_movies > 10
ORDER BY 
    fr.name, fr.production_year DESC;
