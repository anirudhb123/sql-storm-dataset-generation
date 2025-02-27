WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),

MovieDetails AS (
    SELECT 
        m.movie_id, 
        m.movie_title, 
        m.production_year, 
        STRING_AGG(DISTINCT c.role_id::text, ', ') AS roles
    FROM 
        RankedMovies m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id, m.movie_title, m.production_year
),

TopRatedMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title, 
        md.production_year,
        COALESCE(SUM(CASE WHEN i.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS num_awards
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info i ON md.movie_id = i.movie_id
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year
    ORDER BY 
        num_awards DESC
    LIMIT 10
)

SELECT 
    t.movie_id,
    t.movie_title,
    t.production_year,
    t.num_awards,
    c.name AS leading_actor,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
    TopRatedMovies t
JOIN 
    cast_info ci ON t.movie_id = ci.movie_id
JOIN 
    aka_name c ON ci.person_id = c.person_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ci.nr_order = 1  
GROUP BY 
    t.movie_id, t.movie_title, t.production_year, t.num_awards, c.name
ORDER BY 
    t.num_awards DESC, t.movie_title;