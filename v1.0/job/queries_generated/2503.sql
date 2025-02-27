WITH MovieRankings AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        MovieRankings
    WHERE 
        year_rank <= 10
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(m.info, 'No info available') AS movie_info,
        k.keyword AS movie_keyword
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_info m ON t.title = m.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    d.title,
    d.production_year,
    d.movie_info,
    STRING_AGG(d.movie_keyword, ', ') AS keywords,
    CASE 
        WHEN d.movie_info IS NULL THEN 'Information Missing'
        ELSE 'Information Available'
    END AS info_status
FROM 
    MovieDetails d
GROUP BY 
    d.title, d.production_year, d.movie_info
ORDER BY 
    d.production_year DESC, STRING_AGG(d.movie_keyword, ', ') DESC;
