WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name, ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT co.name, ', ') AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword, ', ') AS keywords,
        GROUP_CONCAT(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.movie_id
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = m.movie_id
    LEFT JOIN 
        role_type r ON r.id = c.role_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.aka_names,
        md.company_names,
        md.keywords,
        md.roles,
        md.cast_count,
        RANK() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) as rank
    FROM 
        MovieDetails md
)
SELECT 
    tm.rank,
    tm.movie_title,
    tm.production_year,
    tm.aka_names,
    tm.company_names,
    tm.keywords,
    tm.roles,
    tm.cast_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
