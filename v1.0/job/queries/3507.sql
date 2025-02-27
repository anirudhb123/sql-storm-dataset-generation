WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(ci.note, 'No notable cast info') AS notable_cast
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS note
         FROM 
            cast_info c
         JOIN 
            aka_name a ON c.person_id = a.person_id
         JOIN 
            role_type r ON c.role_id = r.id
         GROUP BY 
            c.movie_id) ci ON tm.movie_id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.notable_cast,
    COALESCE(cn.name, 'Independent') AS production_company
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
ORDER BY 
    md.production_year DESC, md.title;
