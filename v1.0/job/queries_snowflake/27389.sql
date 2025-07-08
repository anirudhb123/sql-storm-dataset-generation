
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS casting_count, 
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON mi.movie_id = t.id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mi.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'genre'
        ) 
        AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        casting_count,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.casting_count, 
    tm.actor_names,
    ct.kind AS company_type,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS production_companies 
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    tm.title, tm.production_year, tm.casting_count, tm.actor_names, ct.kind
ORDER BY 
    tm.production_year DESC, tm.casting_count DESC;
