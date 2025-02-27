WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 3  -- Fetch top 3 keywords for each movie
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.keyword,
        GROUP_CONCAT(DISTINCT CONCAT(a.name, ' as ', rt.role)) AS cast_details
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.keyword
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    md.cast_details
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC, 
    md.title;
