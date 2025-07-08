
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ka.person_id) AS actor_count,
        LISTAGG(DISTINCT ka.name, ', ') WITHIN GROUP (ORDER BY ka.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year,
        actor_count,
        actors,
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND 
        actor_count > 5
)
SELECT 
    fm.title_id,
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.actors,
    fm.keywords
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 10
ORDER BY 
    fm.rank;
