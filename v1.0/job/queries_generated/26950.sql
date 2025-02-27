WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        GROUP_CONCAT(DISTINCT COALESCE(k.keyword, 'N/A')) AS keywords,
        COUNT(c.id) AS total_cast
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    AND 
        cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_names,
        keywords,
        total_cast,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    tm.rank,
    tm.movie_title,
    tm.production_year,
    tm.actor_names,
    tm.keywords,
    tm.total_cast
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
