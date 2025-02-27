WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t 
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
), 
RelatedMovies AS (
    SELECT 
        m.title AS movie_title,
        COALESCE(ml.linked_movie_id, 0) AS linked_id,
        ml.link_type_id,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ml.link_type_id) AS link_rank
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        m.production_year >= 2000
), 
CastDetails AS (
    SELECT 
        ci.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_played
    FROM 
        cast_info ci 
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        title t ON ci.movie_id = t.id 
    GROUP BY 
        ci.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 3
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id 
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_title,
    rm.linked_id,
    c.name AS actor_name,
    c.movie_count,
    c.movies_played,
    rk.rank_by_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    RankedMovies rk
JOIN 
    RelatedMovies rm ON rk.title = rm.movie_title
JOIN 
    CastDetails c ON rm.linked_id = c.person_id
LEFT JOIN 
    MovieKeywords mk ON rm.linked_id = mk.movie_id
WHERE 
    rk.rank_by_year = 1 
    AND (c.movie_count > 3 OR mk.keywords IS NOT NULL)
ORDER BY 
    rk.production_year DESC, 
    c.movie_count DESC, 
    rm.link_rank ASC
LIMIT 50;
