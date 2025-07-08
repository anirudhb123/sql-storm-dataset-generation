
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_stats AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
movie_benchmarks AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ks.keyword_count,
        ks.keywords,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS cast_rank,
        ROW_NUMBER() OVER (ORDER BY ks.keyword_count DESC) AS keyword_rank
    FROM 
        ranked_movies rm
    JOIN 
        keyword_stats ks ON rm.movie_id = ks.movie_id
)
SELECT 
    mb.movie_id,
    mb.title,
    mb.production_year,
    mb.cast_count,
    mb.keyword_count,
    mb.keywords,
    mb.cast_rank,
    mb.keyword_rank
FROM 
    movie_benchmarks mb
WHERE 
    mb.production_year >= 2000
ORDER BY 
    mb.cast_rank, mb.keyword_rank;
