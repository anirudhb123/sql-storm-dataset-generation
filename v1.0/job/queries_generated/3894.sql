WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ca ON a.id = ca.movie_id
    GROUP BY 
        a.title, a.production_year, c.name
),
HighActorMovies AS (
    SELECT 
        title, 
        production_year, 
        company_name 
    FROM 
        RankedMovies 
    WHERE 
        actor_count > 5
),
MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(m.info, 'No info available') AS extra_info,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info m ON a.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    GROUP BY 
        a.title, a.production_year, m.info
)
SELECT 
    h.title AS movie_title,
    h.production_year,
    h.company_name,
    d.extra_info,
    d.keyword_count
FROM 
    HighActorMovies h
JOIN 
    MovieDetails d ON h.title = d.title AND h.production_year = d.production_year
WHERE 
    h.rank <= 10
ORDER BY 
    h.production_year DESC, h.company_name;
