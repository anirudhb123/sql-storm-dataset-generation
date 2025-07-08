WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS num_cast_members
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.keywords,
        rm.num_cast_members,
        ROW_NUMBER() OVER (ORDER BY rm.num_cast_members DESC, rm.production_year DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
    LIMIT 10
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.keywords,
    tm.num_cast_members,
    ARRAY_AGG(DISTINCT an.name) AS actor_names,
    ARRAY_AGG(DISTINCT ci.role_id) AS role_ids
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT movie_id FROM complete_cast WHERE subject_id IN (SELECT person_id FROM aka_name))
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    tm.movie_title, tm.production_year, tm.keywords, tm.num_cast_members
ORDER BY 
    tm.num_cast_members DESC;
