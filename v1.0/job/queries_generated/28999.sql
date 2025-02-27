WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        COUNT(ca.person_id) AS actor_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY COUNT(ca.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ca ON at.id = ca.movie_id
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        at.id, at.title, at.production_year, ak.name
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        actor_count,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    TM.movie_title,
    TM.production_year,
    TM.actor_name,
    TM.actor_count,
    TM.keywords,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    TopMovies TM
LEFT JOIN 
    movie_info mi ON TM.movie_title = mi.info
ORDER BY 
    TM.production_year DESC, TM.actor_count DESC;
