WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), movie_info_aggregates AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS all_info,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.num_cast_members,
    rm.cast_names,
    mia.all_info,
    mia.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info_aggregates mia ON rm.movie_id = mia.movie_id
ORDER BY 
    rm.production_year DESC, rm.num_cast_members DESC
LIMIT 10;
