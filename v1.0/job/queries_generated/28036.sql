WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        AVG(CAST(c.nr_order AS FLOAT)) AS avg_nr_order, 
        COUNT(DISTINCT ca.id) AS total_cast_members
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON c.movie_id = cc.movie_id AND c.id = cc.subject_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        avg_nr_order, 
        total_cast_members,
        RANK() OVER (ORDER BY avg_nr_order DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        total_cast_members > 5
),
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        tm.avg_nr_order, 
        tm.total_cast_members,
        k.keyword AS primary_keyword,
        co.name AS production_company,
        pi.info AS director_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1) = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        person_info pi ON pi.person_id = (SELECT person_id FROM cast_info WHERE movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1) LIMIT 1) AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director' LIMIT 1)
)
SELECT 
    title, 
    production_year, 
    avg_nr_order, 
    total_cast_members, 
    primary_keyword,
    production_company,
    director_info
FROM 
    MovieDetails
WHERE 
    rank <= 10
ORDER BY 
    avg_nr_order DESC;
