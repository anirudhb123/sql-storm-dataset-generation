WITH RankedMovies AS (
    SELECT 
        a.title, 
        at.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        title a ON at.id = a.id
    LEFT JOIN 
        cast_info c ON at.movie_id = c.movie_id
    GROUP BY 
        a.title, at.production_year
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        mk.keywords,
        CASE 
            WHEN rm.rank <= 5 THEN 'Top Movie'
            ELSE 'Others'
        END AS category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = (
            SELECT 
                movie_id 
            FROM 
                aka_title 
            WHERE 
                title = rm.title 
            LIMIT 1
        )
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS actor_count,
    md.keywords,
    md.category
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.actor_count DESC
LIMIT 20;
