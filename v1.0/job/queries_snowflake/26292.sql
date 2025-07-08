
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_actors,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        total_actors, 
        actor_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5  
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_actors,
    tm.actor_names,
    mci.info AS company_info,
    ci.kind AS company_type,
    CASE 
        WHEN tm.total_actors > 20 THEN 'Blockbuster'
        WHEN tm.total_actors BETWEEN 10 AND 20 THEN 'Hit'
        ELSE 'Flop'
    END AS performance_category
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mci ON tm.movie_id = mci.movie_id AND mci.info_type_id = (SELECT id FROM info_type WHERE info = 'Company')
LEFT JOIN 
    comp_cast_type ci ON mc.company_type_id = ci.id
ORDER BY 
    tm.production_year DESC, 
    tm.total_actors DESC;
