
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        movie_info mi ON at.id = mi.movie_id
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
        AND mi.info IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        actors
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actors,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title)
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    tm.title, tm.production_year, tm.actor_count, tm.actors
ORDER BY 
    tm.actor_count DESC, tm.production_year DESC;
