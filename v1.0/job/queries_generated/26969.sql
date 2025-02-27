WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(ak.name, ', ') AS actor_names
    FROM 
        aka_title at
    JOIN 
        movie_info mi ON at.id = mi.movie_id
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        actor_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names,
    kt.kind AS genre,
    cn.name AS company_name,
    ci.kind AS company_type
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_title = (
            SELECT title 
            FROM title 
            WHERE id = mc.movie_id
        )
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    kind_type kt ON kt.id = (SELECT kind_id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC, tm.production_year ASC;
