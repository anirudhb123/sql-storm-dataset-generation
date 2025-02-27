WITH filtered_movies AS (
    SELECT 
        mk.movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    JOIN 
        aka_name ak ON ak.person_id = (
            SELECT 
                ci.person_id 
            FROM 
                cast_info ci 
            WHERE 
                ci.movie_id = mk.movie_id
            LIMIT 1)
    WHERE 
        mi.info LIKE '%blockbuster%' AND
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mk.movie_id, mt.title, mt.production_year
),
brief_cast AS (
    SELECT 
        ci.movie_id, 
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names, 
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        cast_info ci
    JOIN 
        name cn ON ci.person_id = cn.id
    GROUP BY 
        ci.movie_id
),
movie_benchmarks AS (
    SELECT 
        fm.movie_id,
        fm.movie_title,
        fm.production_year,
        fm.aka_names,
        bc.cast_names,
        bc.num_cast_members
    FROM 
        filtered_movies fm
    LEFT JOIN 
        brief_cast bc ON fm.movie_id = bc.movie_id
)
SELECT 
    mb.movie_id,
    mb.movie_title,
    mb.production_year,
    mb.aka_names,
    mb.cast_names,
    mb.num_cast_members,
    LENGTH(mb.movie_title) AS title_length,
    (SELECT COUNT(*) FROM movie_info WHERE movie_id = mb.movie_id) AS info_count
FROM 
    movie_benchmarks mb
ORDER BY 
    mb.production_year DESC, 
    LENGTH(mb.movie_title) DESC;
