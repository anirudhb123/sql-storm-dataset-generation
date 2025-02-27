WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
TopMovies AS (
    SELECT 
        md.movie_id, 
        md.title, 
        md.production_year,
        md.keyword
    FROM 
        MovieDetails md
    WHERE 
        md.rn <= 5
),
PersonDetails AS (
    SELECT 
        a.id AS person_id,
        a.name, 
        r.role, 
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.id, a.name, r.role
    HAVING 
        COUNT(ci.movie_id) > 3
),
FinalBenchmark AS (
    SELECT 
        t.movie_id, 
        t.title, 
        string_agg(DISTINCT p.name, ', ') AS cast_names,
        MAX(p.movie_count) AS cast_movies
    FROM 
        TopMovies t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        PersonDetails p ON c.person_id = p.person_id
    GROUP BY 
        t.movie_id, t.title
)

SELECT 
    fb.movie_id, 
    fb.title, 
    fb.cast_names, 
    fb.cast_movies,
    CASE 
        WHEN fb.cast_movies IS NULL THEN 'No Cast Information'
        WHEN fb.cast_movies >= 10 THEN 'Popular Cast'
        ELSE 'Less Known Cast'
    END AS cast_status
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.title ASC;
