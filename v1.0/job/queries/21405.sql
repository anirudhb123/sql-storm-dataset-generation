WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies,
        t.kind_id,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), 
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
), 
DetailedMovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No Info Available') AS additional_info,
        STRING_AGG(DISTINCT c.name, ', ') AS companies_involved,
        COUNT(DISTINCT f.person_id) AS featured_actor_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        FilteredActors f ON ci.person_id = f.person_id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    GROUP BY 
        m.movie_id, m.title, m.production_year, mi.info
)
SELECT 
    d.title,
    d.production_year,
    d.additional_info,
    d.companies_involved,
    d.featured_actor_count,
    CASE 
        WHEN d.featured_actor_count >= 10 THEN 'Many' 
        WHEN d.featured_actor_count BETWEEN 5 AND 9 THEN 'Moderate' 
        ELSE 'Few' 
    END AS actor_category,
    CASE 
        WHEN d.production_year IS NOT NULL THEN 
            (SELECT AVG(sp.production_year) FROM 
                (SELECT DISTINCT production_year FROM title) sp WHERE production_year < d.production_year)
        ELSE NULL 
    END AS avg_year_before
FROM 
    DetailedMovieInfo d
WHERE 
    d.title LIKE '%Adventure%'
    AND d.production_year > (SELECT AVG(production_year) FROM title)
ORDER BY 
    d.production_year DESC, 
    d.title DESC;
