
WITH movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id, m.title
),
movies_with_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON ci.movie_id = m.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    GROUP BY 
        m.id, m.title
),
ranked_movies AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.keywords,
        mwc.cast_count,
        mwc.cast_names,
        ROW_NUMBER() OVER (ORDER BY mwc.cast_count DESC, mwk.title ASC) AS rank
    FROM 
        movies_with_keywords mwk
    JOIN 
        movies_with_cast mwc ON mwk.movie_id = mwc.movie_id
)
SELECT 
    r.rank,
    r.title,
    r.keywords,
    r.cast_count,
    r.cast_names
FROM 
    ranked_movies r
WHERE 
    r.rank <= 10
ORDER BY 
    r.rank;
