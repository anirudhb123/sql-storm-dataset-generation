
WITH Movie_CC AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        mt.production_year >= 2000 
        AND mt.title IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
),
Top_Movies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        actor_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        Movie_CC
)
SELECT 
    title,
    production_year,
    cast_count,
    actor_names,
    keywords
FROM 
    Top_Movies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, cast_count DESC;
