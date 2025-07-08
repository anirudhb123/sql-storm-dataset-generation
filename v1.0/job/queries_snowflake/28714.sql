
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(ca.id) AS cast_count,
        LISTAGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info ca ON t.id = ca.movie_id
    JOIN 
        aka_name an ON ca.person_id = an.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMoviesWithKeywords AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count,
        rm.actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.actor_names
),
FinalRanking AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        actor_names, 
        keywords,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMoviesWithKeywords
)
SELECT 
    fr.movie_id, 
    fr.title, 
    fr.production_year, 
    fr.cast_count, 
    fr.actor_names, 
    fr.keywords
FROM 
    FinalRanking fr
WHERE 
    fr.rank <= 10
ORDER BY 
    fr.rank;
