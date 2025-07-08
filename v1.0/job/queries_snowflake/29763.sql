
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(cc.id) AS total_cast_members,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS all_actor_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS all_keywords,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, m.title) AS rank
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS cc ON m.id = cc.movie_id
    LEFT JOIN 
        aka_name AS ak ON cc.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast_members,
    rm.all_actor_names,
    rm.all_keywords
FROM 
    RankedMovies AS rm
WHERE 
    rm.total_cast_members > 5
ORDER BY 
    rm.rank
LIMIT 10;
