WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.rating DESC) AS rank
    FROM
        (SELECT 
            t.id, 
            t.title, 
            t.production_year, 
            AVG(r.rating) AS rating
        FROM 
            aka_title t
        LEFT JOIN 
            movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
        LEFT JOIN 
            (SELECT 
                movie_id, 
                AVG(rating) AS rating 
             FROM 
                movie_info 
             WHERE 
                info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
             GROUP BY movie_id) r ON t.id = r.movie_id
        GROUP BY 
            t.id, t.title, t.production_year) a
),
FeaturedActors AS (
    SELECT 
        c.movie_id, 
        ak.name, 
        COUNT(DISTINCT c.person_id) AS actor_count 
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        c.nr_order = 1  -- Only consider leading actors
    GROUP BY 
        c.movie_id, ak.name
),
HighestRatedMovies AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year 
    FROM 
        RankedMovies r 
    WHERE 
        r.rank <= 5  -- Get top 5 movies per production year
),
FinalResults AS (
    SELECT 
        h.title,
        h.production_year,
        COALESCE(f.actor_count, 0) AS lead_actor_count
    FROM 
        HighestRatedMovies h
    LEFT JOIN 
        FeaturedActors f ON h.movie_id = f.movie_id
)
SELECT 
    *,
    CASE 
        WHEN lead_actor_count > 0 THEN 'Featuring ' || lead_actor_count || ' leading actors'
        ELSE 'No leading actors'
    END AS actor_description
FROM 
    FinalResults
ORDER BY 
    production_year DESC, title;
