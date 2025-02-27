WITH MovieRoleCounts AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS role_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.title
),

KeywordCounts AS (
    SELECT 
        m.title AS movie_title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.title
),

MovieInfo AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COALESCE(rc.role_count, 0) AS role_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        a.kind_id,
        a.imdb_index
    FROM 
        aka_title a
    LEFT JOIN 
        MovieRoleCounts rc ON a.title = rc.movie_title
    LEFT JOIN 
        KeywordCounts kc ON a.title = kc.movie_title
)

SELECT 
    mi.movie_title,
    mi.production_year,
    mi.role_count,
    mi.keyword_count,
    kt.kind AS kind_type,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors
FROM 
    MovieInfo mi
LEFT JOIN 
    kind_type kt ON mi.kind_id = kt.id
LEFT JOIN 
    movie_companies mc ON mi.production_year = mc.movie_id
LEFT JOIN 
    aka_name ak ON mc.company_id = ak.person_id
GROUP BY 
    mi.movie_title, mi.production_year, mi.role_count, mi.keyword_count, kt.kind
ORDER BY 
    mi.production_year DESC, mi.movie_title;
