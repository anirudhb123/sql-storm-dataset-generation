WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
PopularTitles AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(*) AS keyword_count
    FROM 
        RankedTitles
    GROUP BY 
        movie_title, production_year
    HAVING 
        COUNT(*) > 2
),
TopMovies AS (
    SELECT 
        pt.movie_title,
        pt.production_year,
        a.name AS actor_name,
        COUNT(ci.id) AS num_cast_members
    FROM 
        PopularTitles pt
    JOIN 
        complete_cast cc ON pt.movie_title = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        pt.movie_title, pt.production_year, a.name
    ORDER BY 
        pt.production_year DESC, num_cast_members DESC
)
SELECT 
    tm.movie_title,
    tm.production_year,
    STRING_AGG(DISTINCT tm.actor_name, ', ') AS actors
FROM 
    TopMovies tm
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC, COUNT(tm.actor_name) DESC;
