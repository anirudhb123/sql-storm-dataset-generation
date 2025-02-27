WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        cct.kind AS role_type,
        mi.info AS movie_info
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type cct ON ci.role_id = cct.id
    WHERE 
        t.production_year >= 2000
        AND ak.name IS NOT NULL
),
KeywordCount AS (
    SELECT 
        md.movie_title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        MovieDetails md
    JOIN 
        movie_keyword mk ON md.movie_title = (SELECT title FROM title WHERE id = md.movie_id)
    GROUP BY 
        md.movie_title
),
RankedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        kc.keyword_count,
        RANK() OVER (ORDER BY kc.keyword_count DESC, md.production_year DESC) AS rank
    FROM 
        MovieDetails md
    JOIN 
        KeywordCount kc ON md.movie_title = kc.movie_title
)
SELECT 
    rm.rank,
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.keyword_count
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
