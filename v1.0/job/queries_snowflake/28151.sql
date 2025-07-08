
WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name), 'No Cast') AS cast_names,
        COALESCE(LISTAGG(DISTINCT kv.keyword, ', ') WITHIN GROUP (ORDER BY kv.keyword), 'No Keywords') AS keywords,
        COALESCE(SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS company_count,
        COUNT(DISTINCT c.person_id) AS unique_cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kv ON mk.keyword_id = kv.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
), 
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_names,
        keywords,
        company_count,
        unique_cast_count,
        RANK() OVER (ORDER BY production_year DESC, unique_cast_count DESC) AS movie_rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    cast_names,
    keywords,
    company_count,
    unique_cast_count,
    movie_rank
FROM 
    RankedMovies
WHERE 
    movie_rank <= 10
ORDER BY 
    movie_rank;
