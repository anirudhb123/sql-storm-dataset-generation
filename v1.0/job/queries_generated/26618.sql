WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id 
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),

CastDetails AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY c.nr_order) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name cn ON c.person_id = cn.person_id
    GROUP BY 
        c.movie_id
),

CompleteMovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.aka_names,
        cd.cast_names,
        COALESCE(movie_info.info, 'No Info') AS additional_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
    LEFT JOIN 
        movie_info movie_info ON md.movie_id = movie_info.movie_id AND movie_info.info_type_id = 1 -- Example info type
)

SELECT 
    *,
    LENGTH(title) AS title_length,
    LENGTH(aka_names) AS aka_names_length,
    LENGTH(cast_names) AS cast_names_length,
    LENGTH(additional_info) AS additional_info_length
FROM 
    CompleteMovieInfo
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC;
